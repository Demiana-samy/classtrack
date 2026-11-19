// Firestore security rules tests. Run from this folder: `npm install && npm test`
// (needs Java 11+; starts the Firestore emulator). CI runs them on every PR.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, query, setDoc, updateDoc, where,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-classtrack',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => {
  await env?.cleanup();
});

// teacher T owns class C1 (code ABC234); student S1 enrolled; student S2 not.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/T'), { name: 'Dr. Amany', role: 'teacher' });
    await setDoc(doc(db, 'users/S1'), { name: 'Ahmed', role: 'student' });
    await setDoc(doc(db, 'users/S2'), { name: 'Sara', role: 'student' });
    await setDoc(doc(db, 'classes/C1'), {
      name: 'Mobile Programming', teacherID: 'T', semester: 'Fall', joinCode: 'ABC234',
    });
    await setDoc(doc(db, 'enrollments/C1_S1'), { classID: 'C1', studentID: 'S1' });
    await setDoc(doc(db, 'attendance_sessions/X1'), {
      classID: 'C1', teacherID: 'T', mode: 'punch_in', status: 'active',
    });
    await setDoc(doc(db, 'attendance_sessions/X1/private/answers'), { correct: [0, 1, 2, 3, 0] });
    await setDoc(doc(db, 'attendance_records/X1_S1'), {
      sessionID: 'X1', studentID: 'S1', classID: 'C1', teacherID: 'T',
      status: 'present', latitude: 30.04, longitude: 31.23,
    });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

describe('classes', () => {
  test('teacher and enrolled student can read the class', async () => {
    await assertSucceeds(getDoc(doc(as('T'), 'classes/C1')));
    await assertSucceeds(getDoc(doc(as('S1'), 'classes/C1')));
  });

  test('a student who did not join cannot read the class or its code', async () => {
    await assertFails(getDoc(doc(as('S2'), 'classes/C1')));
    await assertFails(getDocs(query(collection(as('S2'), 'classes'), where('joinCode', '==', 'ABC234'))));
  });

  test("teacher can list own classes by teacherID", async () => {
    await assertSucceeds(getDocs(query(collection(as('T'), 'classes'), where('teacherID', '==', 'T'))));
  });

  test('teacher can rename but not change owner or join code', async () => {
    await assertSucceeds(updateDoc(doc(as('T'), 'classes/C1'), { name: 'Mobile Prog 2' }));
    await assertFails(updateDoc(doc(as('T'), 'classes/C1'), { teacherID: 'S1' }));
    await assertFails(updateDoc(doc(as('T'), 'classes/C1'), { joinCode: 'ZZZ999' }));
  });

  test('only a teacher can create a class for themselves', async () => {
    await assertSucceeds(setDoc(doc(as('T'), 'classes/C2'), { name: 'DB', teacherID: 'T', joinCode: 'QQQ222' }));
    await assertFails(setDoc(doc(as('S1'), 'classes/C3'), { name: 'X', teacherID: 'S1', joinCode: 'WWW333' }));
  });
});

describe('enrollments', () => {
  test('students cannot enroll themselves directly (joinClass function only)', async () => {
    await assertFails(setDoc(doc(as('S2'), 'enrollments/C1_S2'), { classID: 'C1', studentID: 'S2' }));
  });

  test('a student can leave a class', async () => {
    await assertSucceeds(deleteDoc(doc(as('S1'), 'enrollments/C1_S1')));
  });
});

describe('attendance_records', () => {
  test('student reads own record; other students cannot', async () => {
    await assertSucceeds(getDoc(doc(as('S1'), 'attendance_records/X1_S1')));
    await assertFails(getDoc(doc(as('S2'), 'attendance_records/X1_S1')));
  });

  test('teacher dashboard query (sessionID + teacherID) is allowed', async () => {
    await assertSucceeds(getDocs(query(
      collection(as('T'), 'attendance_records'),
      where('sessionID', '==', 'X1'),
      where('teacherID', '==', 'T'),
    )));
  });

  test('student history query (studentID == me) is allowed', async () => {
    await assertSucceeds(getDocs(query(collection(as('S1'), 'attendance_records'), where('studentID', '==', 'S1'))));
  });

  test('query without a teacherID/studentID filter is denied', async () => {
    await assertFails(getDocs(query(collection(as('S2'), 'attendance_records'), where('sessionID', '==', 'X1'))));
  });

  test('nobody writes records from the app', async () => {
    await assertFails(setDoc(doc(as('S2'), 'attendance_records/X1_S2'), { studentID: 'S2', status: 'present' }));
    await assertFails(updateDoc(doc(as('S1'), 'attendance_records/X1_S1'), { status: 'present' }));
  });
});

describe('attendance_sessions', () => {
  test('enrolled or not, signed-in students can see the session (assignment section 4)', async () => {
    await assertSucceeds(getDoc(doc(as('S2'), 'attendance_sessions/X1')));
  });

  test('clients cannot create sessions', async () => {
    await assertFails(setDoc(doc(as('T'), 'attendance_sessions/X2'), { classID: 'C1', teacherID: 'T' }));
  });

  test('teacher can only close their own session early', async () => {
    await assertFails(updateDoc(doc(as('S1'), 'attendance_sessions/X1'), { status: 'closed' }));
    await assertFails(updateDoc(doc(as('T'), 'attendance_sessions/X1'), { radius: 9999 }));
    await assertSucceeds(updateDoc(doc(as('T'), 'attendance_sessions/X1'), { status: 'closed' }));
  });

  test('quiz answer key is never readable from the app', async () => {
    await assertFails(getDoc(doc(as('S1'), 'attendance_sessions/X1/private/answers')));
    await assertFails(getDoc(doc(as('T'), 'attendance_sessions/X1/private/answers')));
  });
});

describe('users', () => {
  test('role cannot change after registration', async () => {
    await assertFails(updateDoc(doc(as('S1'), 'users/S1'), { role: 'teacher' }));
    await assertSucceeds(updateDoc(doc(as('S1'), 'users/S1'), { name: 'Ahmed Ali' }));
  });
});
