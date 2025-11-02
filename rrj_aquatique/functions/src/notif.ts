import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin } from "./init";

/**
 * Notification for parameter threshold alerts
 * Triggered when 'forNotif/parameters' document changes
 */
export const forNotifAlert = onDocumentWritten(
  "forNotif/parameters",
  async (event) => {
    const afterData = event.data?.after?.data?.();
    if (!afterData) return;

    const alertsToSend: string[] = [];

    // Thresholds configuration
    const thresholds = {
      ph: { min: 6.5, max: 8.0, label: "pH" },
      temperature: { min: 20, max: 30, label: "Temperature" },
      turbidity: { min: 0, max: 11, label: "Turbidity" },
    };

    // Check each parameter
    for (const key of Object.keys(thresholds) as (keyof typeof thresholds)[]) {
      const val = afterData[key];
      if (typeof val !== "number") continue;

      const { min, max, label } = thresholds[key];
      const isOutOfRange = (min !== null && val < min) || (max !== null && val > max);

      if (isOutOfRange) {
        alertsToSend.push(`${label} is out of range: ${val}`);
      }
    }

    // Send notification if needed
    if (alertsToSend.length > 0) {
      try {
        await admin.messaging().send({
          topic: "alerts",
          notification: {
            title: "RRJ Aquatique Alert",
            body: alertsToSend.join(" | "),
          },
        });
        console.log("Notification sent:", alertsToSend.join(" | "));
      } catch (err) {
        console.error("Failed to send notification:", err);
      }
    } else {
      console.log("No alerts to send.");
    }
  }
);

/**
 * Notification for triggered actions
 * Triggered when 'settings/triggered' document changes
 */
export const triggeredStatusAlert = onDocumentWritten(
  "settings/triggered",
  async (event) => {
    const beforeData = event.data?.before?.data?.();
    const afterData = event.data?.after?.data?.();
    if (!afterData) return;

    const messages: string[] = [];

    // Convert Firestore timestamps (if they exist) to milliseconds for comparison
    const beforeFeeding =
      beforeData?.feedingLastTriggered?.toMillis?.() ?? null;
    const afterFeeding =
      afterData.feedingLastTriggered?.toMillis?.() ?? null;

    const beforePh = beforeData?.phLastTriggered?.toMillis?.() ?? null;
    const afterPh = afterData.phLastTriggered?.toMillis?.() ?? null;

    // Check what changed
    const feedingChanged = beforeFeeding !== afterFeeding;
    const phChanged = beforePh !== afterPh;

    // Only include messages for what actually changed
    if (feedingChanged) {
      const grams = afterData.feedingGrams ?? "unknown";
      messages.push(`Feeding was triggered: ${grams} grams`);
    }

    if (phChanged) {
      messages.push("pH balancer was triggered");
    }

    // Only send notification if something changed
    if (messages.length > 0) {
      try {
        await admin.messaging().send({
          topic: "alerts",
          notification: {
            title: "RRJ Aquatique Trigger Update",
            body: messages.join(" | "),
          },
        });
        console.log("Trigger notification sent:", messages.join(" | "));
      } catch (err) {
        console.error("Failed to send trigger notification:", err);
      }
    } else {
      console.log("No trigger changes detected.");
    }
  }
);