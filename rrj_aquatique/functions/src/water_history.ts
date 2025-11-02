import { onSchedule } from "firebase-functions/v2/scheduler";
import { admin, db } from "./init";

// -----------------------------------------------------------------------------
// DAILY WATER HISTORY UPDATE - runs every day at 11PM (Asia/Manila)
// -----------------------------------------------------------------------------
export const dailyWaterHistoryUpdate = onSchedule(
  {
    schedule: "0 23 * * *", // every day at 11PM
    timeZone: "Asia/Manila",
  },
  async (event) => {
    const waterHistoryRef = db.collection("water-history");
    const hourlyRef = db.collection("hourly-water-quality");
    const triggeredRef = db.collection("settings").doc("triggered");
    const containerStatusRef = db.collection("container-levels").doc("status");

    // Get the oldest document in water-history
    const historySnap = await waterHistoryRef.orderBy("timestamp", "asc").limit(1).get();
    if (historySnap.empty) {
      console.log("No document found in water-history");
      return;
    }

    const oldestDoc = historySnap.docs[0].ref;
    const oldData = historySnap.docs[0].data();

    // Define start and end of today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);

    // Get today's hourly-water-quality data
    const hourlySnap = await hourlyRef
      .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(today))
      .where("timestamp", "<", admin.firestore.Timestamp.fromDate(tomorrow))
      .get();

    let avgPh: number | null = null;
    let avgTemp: number | null = null;
    let avgTurbidity: number | null = null;

    if (!hourlySnap.empty) {
      let phSum = 0,
        tempSum = 0,
        turbiditySum = 0;

      hourlySnap.forEach((doc) => {
        const d = doc.data();
        phSum += d.ph || 0;
        tempSum += d.temperature || 0;
        turbiditySum += d.turbidity || 0;
      });

      const count = hourlySnap.size;
      avgPh = Number((phSum / count).toFixed(2));
      avgTemp = Number((tempSum / count).toFixed(2));
      avgTurbidity = Number((turbiditySum / count).toFixed(2));
    } else {
      console.log("No hourly-water-quality data for today, setting values to null");
    }

    // Get triggered settings
    const triggeredSnap = await triggeredRef.get();
    const triggeredData = triggeredSnap.data() || {};
    const feedingLast = triggeredData.feedingLastTriggered ? triggeredData.feedingLastTriggered.toDate() : null;
    const phLast = triggeredData.phLastTriggered ? triggeredData.phLastTriggered.toDate() : null;

    // Get container levels
    const containerSnap = await containerStatusRef.get();
    const containerData = containerSnap.data() || {};
    const foodLevelNow = containerData.foodLevel || 0;
    const phSolutionLevelNow = containerData.phSolutionLevel || 0;

    // Check if triggered today
    const isToday = (d?: Date) =>
      !!d &&
      d.getFullYear() === today.getFullYear() &&
      d.getMonth() === today.getMonth() &&
      d.getDate() === today.getDate();

    const isAutoFeedingEnabledToday = isToday(feedingLast);
    const isAutoPhEnabledToday = isToday(phLast);

    // Manage feeding schedules (keep max 2)
    let feedingSchedules: FirebaseFirestore.Timestamp[] = [];
    if (oldData?.feedingSchedules && Array.isArray(oldData.feedingSchedules)) {
      feedingSchedules = oldData.feedingSchedules.map((t: any) =>
        t instanceof admin.firestore.Timestamp
          ? t
          : admin.firestore.Timestamp.fromDate(new Date(t))
      );
    }

    if (feedingLast) {
      const newTs = admin.firestore.Timestamp.fromDate(feedingLast);
      const exists = feedingSchedules.some((t) => t.toMillis() === newTs.toMillis());
      if (!exists) feedingSchedules.push(newTs);
    }

    feedingSchedules.sort((a, b) => a.toMillis() - b.toMillis());
    if (feedingSchedules.length > 2) feedingSchedules = feedingSchedules.slice(-2);

    // Capture start & end of day levels
    let foodLevelStartOfDay = oldData?.foodLevelStartOfDay ?? foodLevelNow;
    let phSolutionLevelStartOfDay = oldData?.phSolutionLevelStartOfDay ?? phSolutionLevelNow;

    const foodLevelEndOfDay = foodLevelNow;
    const phSolutionLevelEndOfDay = phSolutionLevelNow;

    // Update document
    await oldestDoc.set(
      {
        timestamp: admin.firestore.Timestamp.now(),
        ph: avgPh,
        temp: avgTemp,
        turbidity: avgTurbidity,
        feedingSchedules,
        isAutoFeedingEnabledToday,
        isAutoPhEnabledToday,
        foodLevelStartOfDay,
        foodLevelEndOfDay,
        phSolutionLevelStartOfDay,
        phSolutionLevelEndOfDay,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log(
      `Water-history updated. ph=${avgPh}, temp=${avgTemp}, turbidity=${avgTurbidity}, feedingSchedules=${feedingSchedules.length}, food=${foodLevelEndOfDay}, phSol=${phSolutionLevelEndOfDay}`
    );
  }
);

// -----------------------------------------------------------------------------
// CAPTURE START OF DAY LEVELS - runs every day at midnight (Asia/Manila)
// -----------------------------------------------------------------------------
export const captureStartOfDayLevels = onSchedule(
  {
    schedule: "0 0 * * *", // midnight
    timeZone: "Asia/Manila",
  },
  async (event) => {
    const containerStatusRef = db.collection("container-levels").doc("status");
    const waterHistoryRef = db.collection("water-history");

    const containerSnap = await containerStatusRef.get();
    const data = containerSnap.data() || {};
    const foodLevel = data.foodLevel || 0;
    const phSolutionLevel = data.phSolutionLevel || 0;

    const newestSnap = await waterHistoryRef.orderBy("timestamp", "desc").limit(1).get();
    if (newestSnap.empty) {
      console.log("No document found in water-history to update.");
      return;
    }

    await newestSnap.docs[0].ref.set(
      {
        foodLevelStartOfDay: foodLevel,
        phSolutionLevelStartOfDay: phSolutionLevel,
      },
      { merge: true }
    );

    console.log("Captured start of day levels:", { foodLevel, phSolutionLevel });
  }
);
