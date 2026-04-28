const crypto = require("crypto");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID;
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET;
const RAZORPAY_WEBHOOK_SECRET = process.env.RAZORPAY_WEBHOOK_SECRET;

exports.razorpayWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const signature = req.get("x-razorpay-signature") || "";
    const rawBody = req.rawBody || Buffer.from(JSON.stringify(req.body));
    const expected = crypto
      .createHmac("sha256", RAZORPAY_WEBHOOK_SECRET || "")
      .update(rawBody)
      .digest("hex");

    if (!signature || signature !== expected) {
      return res.status(400).send("Invalid signature");
    }

    if (req.body?.event !== "payment.captured") {
      return res.status(200).send("Ignored");
    }

    const payment = req.body?.payload?.payment?.entity;
    const paymentLinkId = payment?.payment_link_id || payment?.notes?.paymentLinkId;
    const internalPaymentId = payment?.notes?.internalPaymentId;
    const capturedAmount = payment?.amount ? Math.floor(payment.amount / 100) : null;
    const razorpayPaymentId = payment?.id;

    let paymentRef = null;
    if (internalPaymentId) {
      const ref = db.collection("payments").doc(internalPaymentId);
      const snap = await ref.get();
      if (snap.exists) paymentRef = ref;
    }

    if (!paymentRef && paymentLinkId) {
      const q = await db
        .collection("payments")
        .where("paymentLinkId", "==", paymentLinkId)
        .limit(1)
        .get();
      if (!q.empty) paymentRef = q.docs[0].ref;
    }

    if (!paymentRef) {
      return res.status(202).send("No payment mapping found");
    }

    const paymentSnap = await paymentRef.get();
    if (!paymentSnap.exists) {
      return res.status(404).send("Payment record missing");
    }

    const paymentDoc = paymentSnap.data();
    if (paymentDoc.status === "success") {
      return res.status(200).send("Already processed");
    }

    if (capturedAmount !== paymentDoc.amount) {
      await paymentRef.update({
        status: "failed",
        rejectionReason: "Amount mismatch",
        razorpayPaymentId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return res.status(200).send("Amount mismatch");
    }

    await markPaymentSuccessAndUnlock(paymentRef.id, razorpayPaymentId, "webhook");
    return res.status(200).send("Payment verified");
  } catch (error) {
    console.error("Webhook processing failed", error);
    return res.status(500).send("Internal error");
  }
});

exports.adminApprovePayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const adminUser = await db.collection("users").doc(context.auth.uid).get();
  if (!adminUser.exists || adminUser.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Admin only");
  }

  const paymentId = data?.paymentId;
  if (!paymentId) {
    throw new functions.https.HttpsError("invalid-argument", "paymentId required");
  }

  await markPaymentSuccessAndUnlock(paymentId, null, "admin_manual", context.auth.uid);
  return { ok: true };
});

async function markPaymentSuccessAndUnlock(paymentId, razorpayPaymentId, mode, adminId) {
  const paymentRef = db.collection("payments").doc(paymentId);
  const paymentSnap = await paymentRef.get();
  if (!paymentSnap.exists) throw new Error("Payment not found");
  const payment = paymentSnap.data();

  await paymentRef.update({
    status: "success",
    verifiedBy: adminId || "system",
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    verificationMode: mode,
    razorpayPaymentId: razorpayPaymentId || payment.razorpayPaymentId || null,
  });

  for (const item of payment.courseItems || []) {
    const accessQuery = await db
      .collection("course_access")
      .where("studentId", "==", payment.userId)
      .where("courseId", "==", item.courseId)
      .limit(1)
      .get();

    if (!accessQuery.empty) {
      await accessQuery.docs[0].ref.update({
        paymentStatus: "approved",
        accessEnabled: true,
        approvedBy: adminId || "system",
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectionReason: null,
      });
      continue;
    }

    await db.collection("course_access").add({
      studentId: payment.userId,
      studentName: payment.userName,
      studentEmail: payment.userEmail,
      courseId: item.courseId,
      courseTitle: item.courseTitle,
      paymentStatus: "approved",
      accessEnabled: true,
      approvedBy: adminId || "system",
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

exports.verifyRazorpayPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const paymentId = data?.paymentId;
  const razorpayPaymentId = data?.razorpayPaymentId;
  if (!paymentId || !razorpayPaymentId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "paymentId and razorpayPaymentId are required",
    );
  }

  const paymentRef = db.collection("payments").doc(paymentId);
  const paymentSnap = await paymentRef.get();
  if (!paymentSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Payment not found");
  }

  const payment = paymentSnap.data();
  if (payment.userId !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "Not your payment");
  }

  const auth = Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString("base64");
  const response = await axios.get(
    `https://api.razorpay.com/v1/payments/${razorpayPaymentId}`,
    { headers: { Authorization: `Basic ${auth}` } },
  );

  const rp = response.data;
  const capturedAmount = rp.amount ? Math.floor(rp.amount / 100) : null;
  if (rp.status !== "captured" || capturedAmount !== payment.amount) {
    throw new functions.https.HttpsError("failed-precondition", "Payment not captured or amount mismatch");
  }

  await markPaymentSuccessAndUnlock(paymentId, razorpayPaymentId, "api_verification");
  return { ok: true };
});
