/**
 * ClassTrack backend. The ONLY code allowed to create sessions and attendance records.
 * Clients can never write attendance_records (see firestore.rules).
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
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

  if (typeof classId !== "string" || !classId) throw new HttpsError("invalid-argument", "Missing classId");
  if (!["punch_in", "quiz"].includes(mode)) throw new HttpsError("invalid-argument", "Bad mode");
  if (!isNum(latitude) || !isNum(longitude)) throw new HttpsError("invalid-argument", "Bad location");
  if (!isNum(radius) || radius < 10 || radius > 500) {
    throw new HttpsError("invalid-argument", "Radius must be 10-500 m");
  }

  const cls = await db.collection("classes").doc(classId).get();
  if (!cls.exists || cls.data().teacherID !== uid) {
    throw new HttpsError("permission-denied", "You can only start sessions for your own classes.");
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

  const ref = db.collection("attendance_sessions").doc();
  const liveQuery = db
    .collection("attendance_sessions")
    .where("classID", "==", classId)
    .where("status", "==", "active");

  // Transaction: two quick taps cannot open two live sessions for one class.
  const expiry = await db.runTransaction(async (tx) => {
    const live = await tx.get(liveQuery);
    const now = Timestamp.now();
    if (live.docs.some((d) => d.data().expiryTime.toMillis() > now.toMillis())) {
      throw new HttpsError("already-exists", "A session is already running for this class");
    }
    const expiryTime = Timestamp.fromMillis(now.toMillis() + SESSION_MS);
    writeSession(tx, ref, { uid, classId, mode, latitude, longitude, radius, questions, now, expiryTime });
    return expiryTime;
  });

  return { sessionId: ref.id, expiryTime: expiry.toMillis() };
});

function writeSession(tx, ref, { uid, classId, mode, latitude, longitude, radius, questions, now, expiryTime }) {
  tx.set(ref, {
    classID: classId,
    teacherID: uid,
    mode,
    latitude,
    longitude,
    radius,
    startTime: now,
    expiryTime,
    status: "active",
  });

  if (mode === "quiz") {
    questions.forEach((q, i) => {
      // Students can read this (no answer inside).
      tx.set(ref.collection("questions").doc(String(i)), {
        order: i,
        text: q.text.trim(),
        options: q.options.map((o) => o.trim()),
      });
    });
    // Teacher/Function only. Correct answers never reach students.
    tx.set(ref.collection("private").doc("answers"), {
      correct: questions.map((q) => q.correctIndex),
    });
  }
}

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
    teacherID: s.teacherID, // lets firestore.rules show records only to this teacher
    timestamp: Timestamp.now(),
    latitude,
    longitude,
    distance: Math.round(distance * 10) / 10,
  };

  // Mode 2: all 5 answers required, score computed here from the private answer key.
  // Out-of-range quiz attempts are still scored for the teacher's report
  // (assignment example: "124 m, Submitted, 5/5, Rejected").
  let quizScore = null;
  const answersValid = Array.isArray(answers) && answers.length === QUIZ_QUESTIONS &&
    answers.every((a) => Number.isInteger(a) && a >= 0 && a <= 3);
  if (s.mode === "quiz") {
    if (!answersValid && distance <= s.radius) return reject("quiz_incomplete");
    if (answersValid) {
      const key = await sessionRef.collection("private").doc("answers").get();
      const correct = key.data().correct;
      quizScore = answers.reduce((sum, a, i) => sum + (a === correct[i] ? 1 : 0), 0);
    }
  }

  // 5) Already attended? Checked and written in one transaction, so two taps
  // at the same moment still give at most one record per student per session.
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(recordRef);
    if (existing.exists && existing.data().status === "present") return reject("already_attended");

    if (distance > s.radius) {
      // Keep a rejected record for the teacher's report. A later in-range attempt may overwrite it.
      tx.set(recordRef, {
        ...base,
        status: "rejected",
        locationVerified: false,
        quizSubmitted: s.mode === "quiz" && answersValid,
        ...(quizScore !== null ? { quizScore } : {}),
      });
      return reject("out_of_range", { distance: base.distance, radius: s.radius });
    }

    tx.set(recordRef, {
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
});

// ---------------------------------------------------------------------------
// joinClass (student): the join code is checked here, never on the phone.
// Clients cannot create enrollments directly (see firestore.rules).
// ---------------------------------------------------------------------------
exports.joinClass = onCall(async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const uid = req.auth.uid;
  const code = typeof req.data?.code === "string"
    ? req.data.code.replace(/[^A-Za-z0-9]/g, "").toUpperCase()
    : "";
  if (code.length < 4) throw new HttpsError("invalid-argument", "Enter the class code");

  const user = await db.collection("users").doc(uid).get();
  if (!user.exists || user.data().role !== "student") {
    throw new HttpsError("permission-denied", "Only students can join a class");
  }

  const found = await db.collection("classes").where("joinCode", "==", code).limit(1).get();
  if (found.empty) throw new HttpsError("invalid-argument", "That class code is not valid.");
  const cls = found.docs[0];

  const enrollmentRef = db.collection("enrollments").doc(`${cls.id}_${uid}`);
  const existing = await enrollmentRef.get();
  if (!existing.exists) {
    await enrollmentRef.set({
      classID: cls.id,
      studentID: uid,
      joinedAt: Timestamp.now(),
    });
  }
  return { classId: cls.id, className: cls.data().name, alreadyJoined: existing.exists };
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

// ---------------------------------------------------------------------------
// When a session closes (timer or "End session"), write an "absent" record for
// every student who was enrolled before it started and has no record.
// The app also computes absentees itself (Session Results), so this only
// makes the stored data complete for reports and Firestore exports.
// ---------------------------------------------------------------------------
exports.markAbsentees = onDocumentUpdated("attendance_sessions/{sessionId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after || before.status === "closed" || after.status !== "closed") return;

  const sessionId = event.params.sessionId;
  const [enrollments, records] = await Promise.all([
    db.collection("enrollments").where("classID", "==", after.classID).get(),
    db.collection("attendance_records").where("sessionID", "==", sessionId).get(),
  ]);
  const hasRecord = new Set(records.docs.map((d) => d.data().studentID));
  const startMs = after.startTime.toMillis();

  const batch = db.batch();
  let writes = 0;
  for (const e of enrollments.docs) {
    const { studentID, joinedAt } = e.data();
    if (!studentID || hasRecord.has(studentID)) continue;
    if (joinedAt && joinedAt.toMillis() > startMs) continue; // joined after the session
    batch.set(db.collection("attendance_records").doc(`${sessionId}_${studentID}`), {
      sessionID: sessionId,
      studentID,
      classID: after.classID,
      teacherID: after.teacherID,
      timestamp: after.expiryTime,
      status: "absent",
      locationVerified: false,
      quizSubmitted: false,
    });
    writes += 1;
    if (writes === 450) break; // one batch is enough for a class
  }
  if (writes > 0) await batch.commit();
});
