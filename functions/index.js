/**
 * ClassTrack backend. The ONLY code allowed to create sessions and attendance records.
 * Clients can never write attendance_records (see firestore.rules).
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const { Timestamp } = admin.firestore;

const SESSION_MS = 2 * 60 * 1000; // exactly 2 minutes
const QUIZ_QUESTIONS = 5;

// Haversine distance in meters.
function distanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

const isNum = (v) => typeof v === "number" && Number.isFinite(v);

// ---------------------------------------------------------------------------
// startSession (teacher)
// ---------------------------------------------------------------------------
exports.startSession = onCall(async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const uid = req.auth.uid;
  const { classId, mode, latitude, longitude, radius, questions } = req.data || {};

  if (!["punch_in", "quiz"].includes(mode)) throw new HttpsError("invalid-argument", "Bad mode");
  if (!isNum(latitude) || !isNum(longitude)) throw new HttpsError("invalid-argument", "Bad location");
  if (!isNum(radius) || radius < 10 || radius > 500) {
    throw new HttpsError("invalid-argument", "Radius must be 10-500 m");
  }

  const cls = await db.collection("classes").doc(String(classId)).get();
  if (!cls.exists || cls.data().teacherID !== uid) {
    throw new HttpsError("permission-denied", "Not your class");
  }

  // Only one live session per class.
  const live = await db
    .collection("attendance_sessions")
    .where("classID", "==", classId)
    .where("status", "==", "active")
    .get();
  const now = Timestamp.now();
  if (live.docs.some((d) => d.data().expiryTime.toMillis() > now.toMillis())) {
    throw new HttpsError("already-exists", "A session is already running for this class");
  }

  if (mode === "quiz") {
    if (!Array.isArray(questions) || questions.length !== QUIZ_QUESTIONS) {
      throw new HttpsError("invalid-argument", `Quiz needs exactly ${QUIZ_QUESTIONS} questions`);
    }
    for (const q of questions) {
      const ok =
        typeof q.text === "string" && q.text.trim() &&
        Array.isArray(q.options) && q.options.length === 4 &&
        q.options.every((o) => typeof o === "string" && o.trim()) &&
        Number.isInteger(q.correctIndex) && q.correctIndex >= 0 && q.correctIndex <= 3;
      if (!ok) throw new HttpsError("invalid-argument", "Invalid quiz question");
    }
  }

  const expiry = Timestamp.fromMillis(now.toMillis() + SESSION_MS);
  const ref = db.collection("attendance_sessions").doc();
  const batch = db.batch();
  batch.set(ref, {
    classID: classId,
    teacherID: uid,
    mode,
    latitude,
    longitude,
    radius,
    startTime: now,
    expiryTime: expiry,
    status: "active",
  });

  if (mode === "quiz") {
    questions.forEach((q, i) => {
      // Students can read this (no answer inside).
      batch.set(ref.collection("questions").doc(String(i)), {
        order: i,
        text: q.text.trim(),
        options: q.options.map((o) => o.trim()),
      });
    });
    // Teacher/Function only. Correct answers never reach students.
    batch.set(ref.collection("private").doc("answers"), {
      correct: questions.map((q) => q.correctIndex),
    });
  }

  await batch.commit();
  return { sessionId: ref.id, expiryTime: expiry.toMillis() };
});

// ---------------------------------------------------------------------------
// submitAttendance (student): all four checks happen here, server side.
// ---------------------------------------------------------------------------
exports.submitAttendance = onCall(async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const uid = req.auth.uid;
  const { sessionId, latitude, longitude, answers } = req.data || {};

  if (typeof sessionId !== "string") throw new HttpsError("invalid-argument", "Missing sessionId");

  const reject = (reason, extra = {}) => ({
    accepted: false,
    status: "rejected",
    reason,
    ...extra,
  });

  const sessionRef = db.collection("attendance_sessions").doc(sessionId);
  const session = await sessionRef.get();
  if (!session.exists) return reject("session_not_found");
  const s = session.data();

  // 1) Session active? Server time only; the phone clock is never trusted.
  const nowMs = Date.now();
  if (s.status !== "active" || nowMs > s.expiryTime.toMillis()) return reject("session_expired");

  // 2) Student enrolled?
  const enrollment = await db.collection("enrollments").doc(`${s.classID}_${uid}`).get();
  if (!enrollment.exists) return reject("not_enrolled");

  // 3) GPS available?
  if (!isNum(latitude) || !isNum(longitude)) return reject("no_gps");

  // 4) Distance <= radius?
  const distance = distanceMeters(latitude, longitude, s.latitude, s.longitude);
  const recordRef = db.collection("attendance_records").doc(`${sessionId}_${uid}`);
  const base = {
    sessionID: sessionId,
    studentID: uid,
    classID: s.classID,
    timestamp: Timestamp.now(),
    latitude,
    longitude,
    distance: Math.round(distance * 10) / 10,
  };

  // 5) Already attended? (one present record per student per session)
  const existing = await recordRef.get();
  if (existing.exists && existing.data().status === "present") return reject("already_attended");

  if (distance > s.radius) {
    // Keep a rejected record for the teacher's report. A later in-range attempt may overwrite it.
    await recordRef.set({ ...base, status: "rejected", locationVerified: false, quizSubmitted: false });
    return reject("out_of_range", { distance: base.distance, radius: s.radius });
  }

  // Mode 2: all 5 answers required, score computed here from the private answer key.
  let quizScore = null;
  if (s.mode === "quiz") {
    if (!Array.isArray(answers) || answers.length !== QUIZ_QUESTIONS ||
        !answers.every((a) => Number.isInteger(a) && a >= 0 && a <= 3)) {
      return reject("quiz_incomplete");
    }
    const key = await sessionRef.collection("private").doc("answers").get();
    const correct = key.data().correct;
    quizScore = answers.reduce((sum, a, i) => sum + (a === correct[i] ? 1 : 0), 0);
  }

  await recordRef.set({
    ...base,
    status: "present",
    locationVerified: true,
    quizSubmitted: s.mode === "quiz",
    ...(quizScore !== null ? { quizScore } : {}),
  });

  return {
    accepted: true,
    status: "present",
    distance: base.distance,
    radius: s.radius,
    ...(quizScore !== null ? { quizScore } : {}),
  };
});

// ---------------------------------------------------------------------------
// Close expired sessions every minute (needs Blaze plan / Cloud Scheduler).
// ---------------------------------------------------------------------------
exports.closeExpiredSessions = onSchedule("every 1 minutes", async () => {
  const now = Timestamp.now();
  const snap = await db
    .collection("attendance_sessions")
    .where("status", "==", "active")
    .where("expiryTime", "<=", now)
    .get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.update(d.ref, { status: "closed" }));
  await batch.commit();
});
