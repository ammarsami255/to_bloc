const crypto = require("node:crypto");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;

const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 5;
const MAX_NOTIFICATION_TITLE = 120;
const MAX_NOTIFICATION_BODY = 500;
const MAX_NOTIFICATION_TYPE = 40;

function getTransporter() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || "587");
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    throw new HttpsError(
      "failed-precondition",
      "SMTP credentials are not configured for OTP delivery.",
    );
  }

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: {user, pass},
  });
}

function hashOtp(uid, otp) {
  return crypto.createHash("sha256").update(`${uid}:${otp}`).digest("hex");
}

function hashUnauthenticatedOtp(otp) {
  return crypto.createHash("sha256").update(otp).digest("hex");
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function compactText(value, maxLength) {
  const text = String(value || "").trim();
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength);
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

async function checkRateLimit(email) {
  const now = Date.now();
  const windowStart = admin.firestore.Timestamp.fromMillis(
    now - RATE_LIMIT_WINDOW_MS,
  );

  const snapshot = await db
    .collection("rate_limits")
    .where("email", "==", email.toLowerCase())
    .where("timestamp", ">", windowStart)
    .get();

  if (snapshot.size >= MAX_REQUESTS_PER_WINDOW) {
    throw new HttpsError("resource-exhausted", "rate_limit_exceeded");
  }

  await db.collection("rate_limits").add({
    email: email.toLowerCase(),
    timestamp: admin.firestore.Timestamp.fromMillis(now),
    type: "otp",
  });
}

function getFcmTokens(userData) {
  const tokens = new Set();

  if (typeof userData?.fcmToken === "string" && userData.fcmToken.length > 0) {
    tokens.add(userData.fcmToken);
  }

  const tokenMap = userData?.fcmTokens;
  if (isPlainObject(tokenMap)) {
    for (const entry of Object.values(tokenMap)) {
      if (typeof entry === "string" && entry.length > 0) {
        tokens.add(entry);
      } else if (
        isPlainObject(entry) &&
        typeof entry.token === "string" &&
        entry.token.length > 0
      ) {
        tokens.add(entry.token);
      }
    }
  }

  return [...tokens];
}

async function sendPushToUser(userId, payload) {
  const userDoc = await db.collection("users").doc(userId).get();
  const tokens = getFcmTokens(userDoc.data());
  if (tokens.length === 0) return;

  await Promise.all(
    tokens.map(async (token) => {
      try {
        await admin.messaging().send({
          token,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: payload.data,
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        });
      } catch (error) {
        console.log("FCM send error:", error.message);
      }
    }),
  );
}

exports.sendEmailOtpUnauthenticated = onCall({cors: true}, async (request) => {
  const email = String(request.data?.email || "").trim().toLowerCase();

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "A valid email is required.");
  }

  await checkRateLimit(email);

  const otp = generateOtp();
  const otpId = crypto.randomUUID();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + 10 * 60 * 1000,
  );
  const transporter = getTransporter();
  const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;

  try {
    await transporter.sendMail({
      from: fromAddress,
      to: email,
      subject: "Your verification code",
      text: `Your verification code is ${otp}. It expires in 10 minutes.`,
      html: `<p>Your verification code is <strong>${otp}</strong>.</p><p>It expires in 10 minutes.</p>`,
    });
  } catch (error) {
    console.error("Failed to send email:", error);
    throw new HttpsError(
      "internal",
      "Failed to send verification email. Please try again.",
    );
  }

  await db.collection("email_otps").doc(otpId).set({
    otpId,
    email,
    codeHash: hashUnauthenticatedOtp(otp),
    expiresAt,
    attempts: 0,
    createdAt: serverTimestamp(),
  });

  return {success: true, otpId};
});

exports.verifyEmailOtpUnauthenticated = onCall({cors: true}, async (request) => {
  const otp = String(request.data?.otp || "").trim();
  const otpId = String(request.data?.otpId || "").trim();
  const email = String(request.data?.email || "").trim().toLowerCase();

  if (!/^\d{6}$/.test(otp)) {
    throw new HttpsError("invalid-argument", "OTP must be exactly 6 digits.");
  }

  if (!otpId) {
    throw new HttpsError("invalid-argument", "OTP ID is required.");
  }

  const otpRef = db.collection("email_otps").doc(otpId);
  const otpSnapshot = await otpRef.get();

  if (!otpSnapshot.exists) {
    throw new HttpsError("not-found", "No active OTP was found.");
  }

  const otpData = otpSnapshot.data();
  if (!otpData || otpData.email !== email) {
    throw new HttpsError("permission-denied", "OTP email does not match.");
  }

  if (otpData.expiresAt.toMillis() < Date.now()) {
    await otpRef.delete();
    throw new HttpsError("deadline-exceeded", "otp_expired");
  }

  if ((otpData.attempts || 0) >= 5) {
    await otpRef.delete();
    throw new HttpsError("permission-denied", "too_many_attempts");
  }

  if (hashUnauthenticatedOtp(otp) !== otpData.codeHash) {
    await otpRef.update({
      attempts: admin.firestore.FieldValue.increment(1),
    });
    throw new HttpsError("invalid-argument", "invalid_otp");
  }

  await otpRef.delete();
  return {success: true};
});

exports.sendEmailOtp = onCall({cors: true}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const email = String(
    request.data?.email || request.auth.token.email || "",
  )
    .trim()
    .toLowerCase();

  if (!email) {
    throw new HttpsError("invalid-argument", "A valid email is required.");
  }

  await checkRateLimit(email);

  const otp = generateOtp();
  const uid = request.auth.uid;
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + 10 * 60 * 1000,
  );
  const transporter = getTransporter();
  const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;

  try {
    await transporter.sendMail({
      from: fromAddress,
      to: email,
      subject: "Your verification code",
      text: `Your verification code is ${otp}. It expires in 10 minutes.`,
      html: `<p>Your verification code is <strong>${otp}</strong>.</p><p>It expires in 10 minutes.</p>`,
    });
  } catch (error) {
    console.error("Failed to send email:", error);
    throw new HttpsError("internal", "Failed to send verification email.");
  }

  await db.collection("email_otps").doc(uid).set({
    uid,
    email,
    codeHash: hashOtp(uid, otp),
    expiresAt,
    attempts: 0,
    createdAt: serverTimestamp(),
  });

  return {success: true};
});

exports.onNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const {chatId} = event.params;
    const message = snap.data() || {};
    const senderId = String(message.senderId || "");
    const content = String(message.content || "").trim();

    if (!senderId || !content) return;

    const chatRef = db.collection("chats").doc(chatId);
    const chatDoc = await chatRef.get();
    if (!chatDoc.exists) return;

    const participants = chatDoc.data()?.participants || [];
    if (!Array.isArray(participants) || !participants.includes(senderId)) {
      console.log("Message sender is not a chat participant:", chatId);
      return;
    }

    const recipients = participants.filter((id) => id !== senderId);
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = compactText(senderDoc.data()?.name || "Someone", 100);
    const preview =
      content.length > 50 ? `${content.substring(0, 50)}...` : content;
    const messageTime = message.createdAt || serverTimestamp();

    await chatRef.update({
      lastMessage: content,
      lastMessageTime: messageTime,
    });

    await Promise.all(
      recipients.map(async (recipientId) => {
        const notificationRef = db
          .collection("notifications")
          .doc(recipientId)
          .collection("items")
          .doc();

        const notification = {
          id: notificationRef.id,
          title: "New message",
          body: `${senderName}: ${preview}`,
          type: "chat",
          actionData: {chatId},
          read: false,
          createdAt: serverTimestamp(),
        };

        await notificationRef.set(notification);
        await sendPushToUser(recipientId, {
          title: notification.title,
          body: notification.body,
          data: {
            type: "chat",
            chatId,
            notificationId: notificationRef.id,
          },
        });
      }),
    );
  },
);

exports.sendNotification = onCall({cors: true}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }

  if (request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Admin access is required.");
  }

  const userId = String(request.data?.userId || "").trim();
  const title = compactText(request.data?.title, MAX_NOTIFICATION_TITLE);
  const body = compactText(request.data?.body, MAX_NOTIFICATION_BODY);
  const type = compactText(request.data?.type || "info", MAX_NOTIFICATION_TYPE);
  const actionData = isPlainObject(request.data?.actionData)
    ? request.data.actionData
    : null;

  if (!userId || !title || !body) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  const notificationRef = db
    .collection("notifications")
    .doc(userId)
    .collection("items")
    .doc();

  await notificationRef.set({
    id: notificationRef.id,
    title,
    body,
    type,
    actionData,
    read: false,
    createdAt: serverTimestamp(),
  });

  await sendPushToUser(userId, {
    title,
    body,
    data: {
      type,
      notificationId: notificationRef.id,
      ...(actionData || {}),
    },
  });

  return {success: true};
});

exports.saveToken = onCall({cors: true}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }

  const token = String(request.data?.token || "").trim();
  const platform = compactText(request.data?.platform || "unknown", 40);

  if (!token || token.length > 4096) {
    throw new HttpsError("invalid-argument", "A valid token is required.");
  }

  const userId = request.auth.uid;
  const tokenHash = crypto.createHash("sha256").update(token).digest("hex");

  await db
    .collection("users")
    .doc(userId)
    .set(
      {
        fcmToken: token,
        fcmTokenUpdatedAt: serverTimestamp(),
        fcmTokens: {
          [tokenHash]: {
            token,
            platform,
            updatedAt: serverTimestamp(),
          },
        },
      },
      {merge: true},
    );

  return {success: true};
});

exports.deleteToken = onCall({cors: true}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }

  const userId = request.auth.uid;
  const token = String(request.data?.token || "").trim();
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    return {success: true};
  }

  const updates = {
    fcmTokenUpdatedAt: serverTimestamp(),
  };

  if (!token || userDoc.data()?.fcmToken === token) {
    updates.fcmToken = admin.firestore.FieldValue.delete();
  }

  if (token) {
    const tokenHash = crypto.createHash("sha256").update(token).digest("hex");
    updates[`fcmTokens.${tokenHash}`] = admin.firestore.FieldValue.delete();
  }

  await userRef.update(updates);
  return {success: true};
});
