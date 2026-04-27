const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");

initializeApp();

exports.sendPushNotification = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    region: "europe-west1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("No data in notification document");
      return;
    }

    const data = snapshot.data();
    const { fcmToken, title, body, bookingId, status, userId } = data;

    if (!fcmToken) {
      logger.warn("No FCM token found, skipping notification", { userId });
      await snapshot.ref.update({
        sent: false,
        error: "No FCM token",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    if (!title || !body) {
      logger.warn("Missing title or body", { userId });
      await snapshot.ref.update({
        sent: false,
        error: "Missing title or body",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const message = {
      notification: {
        title,
        body,
      },
      data: {
        bookingId: bookingId || "",
        status: status || "",
        notificationId: event.params.notificationId,
      },
      token: fcmToken,
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
          },
        },
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "beear_cars_wash_channel",
        },
      },
    };

    try {
      const response = await getMessaging().send(message);
      logger.info("Notification sent successfully", {
        messageId: response,
        userId,
        bookingId,
      });

      await snapshot.ref.update({
        sent: true,
        sentAt: FieldValue.serverTimestamp(),
        messageId: response,
      });
    } catch (error) {
      logger.error("Failed to send notification", {
        error: error.message,
        code: error.code,
        userId,
        bookingId,
      });

      if (
        error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-registration-token"
      ) {
        await _cleanupInvalidToken(userId, fcmToken);
      }

      await snapshot.ref.update({
        sent: false,
        error: error.message,
        errorCode: error.code || null,
        processedAt: FieldValue.serverTimestamp(),
      });
    }
  }
);

async function _cleanupInvalidToken(userId, invalidToken) {
  if (!userId) return;

  try {
    const db = getFirestore();
    const userDoc = await db.collection("users").doc(userId).get();

    if (userDoc.exists) {
      const userData = userDoc.data();
      if (userData.fcmToken === invalidToken) {
        await db.collection("users").doc(userId).update({
          fcmToken: FieldValue.delete(),
          fcmTokenUpdatedAt: FieldValue.serverTimestamp(),
        });
        logger.info("Cleaned up invalid FCM token", { userId });
      }
    }
  } catch (err) {
    logger.error("Failed to cleanup invalid token", {
      error: err.message,
      userId,
    });
  }
}
