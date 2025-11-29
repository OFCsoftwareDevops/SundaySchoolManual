const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// V2 Firestore trigger with explicit region (fixes deploy error)
exports.notifyNewLesson = onDocumentCreated(
  {
    document: "lessons/{lessonId}",
    region: "us-central1",  // ← CRITICAL: Explicit region for V2
  },
  async (event) => {
    const lessonId = event.params.lessonId;  // e.g., "2025-12-7"
    logger.info("New lesson created:", lessonId);

    // Parse date from document ID
    const parts = lessonId.split("-");
    if (parts.length !== 3) {
      logger.warn("Invalid lesson ID format:", lessonId);
      return;
    }

    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10);
    const day = parseInt(parts[2], 10);

    const lessonDate = new Date(year, month - 1, day);
    if (isNaN(lessonDate.getTime())) {
      logger.warn("Invalid date from lesson ID:", lessonId);
      return;
    }

    // Only notify if it's a Sunday (0 = Sunday in JS Date.getDay())
    if (lessonDate.getDay() !== 0) {
      logger.info("Not a Sunday — skipping notification for", lessonId);
      return;
    }

    // Get document data
    const snapshot = event.data;
    if (!snapshot.exists) {
      logger.warn("No data in new lesson document");
      return;
    }
    const data = snapshot.data();

    // Only notify if there's actual content (teen or adult notes)
    if (!data.teen && !data.adult) {
      logger.info("Empty lesson — no notification");
      return;
    }

    const payload = {
      notification: {
        title: "New Sunday School Lesson!",
        body: `Lesson for ${lessonDate.toLocaleDateString()} is ready. Tap to study!`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        date: lessonId,  // For deep-linking to this date
      },
      topic: "all_users",  // All subscribed users get it
    };

    try {
      const response = await admin.messaging().send(payload);
      logger.info("Notification sent successfully:", response);
    } catch (error) {
      logger.error("Failed to send notification:", error);
    }
  }
);