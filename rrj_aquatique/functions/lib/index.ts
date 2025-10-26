import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

export const waterQualityAlert = onDocumentWritten(
  "current-water-quality/live",
  async (event) => {
    // Get the new document data
    const afterData = event.data?.after?.data?.();
    if (!afterData) return;

    const lastUpdated = afterData.lastUpdated;
    if (!lastUpdated) return;

    // Reference to store alert state
    const alertStateRef = admin.firestore().collection("water-alerts").doc("live");
    const alertStateDoc = await alertStateRef.get();
    const alertState = alertStateDoc.exists ? alertStateDoc.data() : {};

    const alerts: string[] = [];
    const updatedAlertState: Record<string, boolean | FirebaseFirestore.Timestamp> = {
      timestamp: lastUpdated.toDate(),
    };

    // Function to check alert thresholds
    const checkAlert = (
      field: string,
      value: number,
      min: number | null,
      max: number | null,
      message: string
    ) => {
      const previouslyAlerted = alertState?.[field] === true;
      if ((max !== null && value > max) || (min !== null && value < min)) {
        if (!previouslyAlerted) alerts.push(message);
        updatedAlertState[field] = true;
      } else {
        updatedAlertState[field] = false;
      }
    };

    // Check only temperature, pH, turbidity
    checkAlert("temperature", afterData.temperature, 20, 30, "Temperature out of range!");
    checkAlert("ph", afterData.ph, 6.5, 8.0, "pH out of range!");
    checkAlert("turbidity", afterData.turbidity, 0, 5, "Water clarity is poor!");

    // Send notification to topic if any alerts
    if (alerts.length > 0) {
      await admin.messaging().send({
        topic: "alerts", // Fixed: use `send()` with topic
        notification: {
          title: "⚠️ RRJ Aquatique Alert",
          body: alerts.join(" "),
        },
      });
      console.log("Notification sent:", alerts.join(" "));
    }

    // Update alert state in Firestore
    await alertStateRef.set(updatedAlertState, { merge: true });
  }
);
