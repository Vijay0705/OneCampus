// ✅ FIXED — Full CRUD timetable backed by Firestore
const express = require('express');
const router = express.Router();
const { getFirestore } = require('../config/firebase');
const { authenticate, authorize } = require('../middleware/auth');

const COLLECTION = 'timetable';

/* ──────────────────────────────────────────────────────────────
   GET /api/timetable?department=CSE&year=1st Year&section=A
   Public (authenticated only) — students & staff can read
────────────────────────────────────────────────────────────── */
router.get('/timetable', authenticate, async (req, res) => {
  try {
    const { department, year, section } = req.query;

    if (!department || !year || !section) {
      return res.status(400).json({
        success: false,
        message: 'department, year, and section are required',
      });
    }

    const db = getFirestore();
    // ✅ FIXED — query without orderBy to avoid index requirement;
    //   sorted JS-side so app works even before Firestore index is built
    const snapshot = await db
      .collection(COLLECTION)
      .where('department', '==', department)
      .where('year', '==', year)
      .where('section', '==', section)
      .get();

    const data = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => {
        const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
        const dayDiff = days.indexOf(a.day) - days.indexOf(b.day);
        if (dayDiff !== 0) return dayDiff;
        return (a.startTime || '').localeCompare(b.startTime || '');
      });

    return res.json({ success: true, data });
  } catch (error) {
    console.error('GET timetable error:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

/* ──────────────────────────────────────────────────────────────
   POST /api/timetable/add   (Admin / Staff only)
   Body: { department, year, section, day, subject, room, startTime, endTime }
────────────────────────────────────────────────────────────── */
router.post(
  '/timetable/add',
  authenticate,
  authorize('admin', 'staff'),
  async (req, res) => {
    try {
      const { department, year, section, day, subject, room, startTime, endTime } =
        req.body;

      if (!department || !year || !section || !day || !subject || !startTime || !endTime) {
        return res.status(400).json({
          success: false,
          message: 'department, year, section, day, subject, startTime, endTime are required',
        });
      }

      const db = getFirestore();
      const ref = db.collection(COLLECTION).doc();

      // ✅ ADDED — check for duplicate slot (same class, day, startTime)
      const dupSnap = await db
        .collection(COLLECTION)
        .where('department', '==', department)
        .where('year', '==', year)
        .where('section', '==', section)
        .where('day', '==', day)
        .where('startTime', '==', startTime)
        .get();

      if (!dupSnap.empty) {
        return res.status(409).json({
          success: false,
          message: 'A period already exists for this slot. Edit or delete it first.',
        });
      }

      const newPeriod = {
        id: ref.id,
        department,
        year,
        section,
        day,
        subject,
        room: room || '',
        startTime,
        endTime,
        createdBy: req.user?.uid || 'unknown',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      await ref.set(newPeriod);

      return res.status(201).json({
        success: true,
        message: 'Period added successfully',
        data: newPeriod,
      });
    } catch (error) {
      console.error('POST timetable/add error:', error);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
  }
);

/* ──────────────────────────────────────────────────────────────
   PUT /api/timetable/:id   (Admin / Staff only)
────────────────────────────────────────────────────────────── */
router.put(
  '/timetable/:id',
  authenticate,
  authorize('admin', 'staff'),
  async (req, res) => {
    try {
      const { id } = req.params;
      const { department, year, section, day, subject, room, startTime, endTime } =
        req.body;

      const db = getFirestore();
      const docRef = db.collection(COLLECTION).doc(id);
      const docSnap = await docRef.get();

      if (!docSnap.exists) {
        return res.status(404).json({ success: false, message: 'Period not found' });
      }

      // ✅ UPDATED — merge only provided fields
      const updates = {
        ...(department && { department }),
        ...(year && { year }),
        ...(section && { section }),
        ...(day && { day }),
        ...(subject && { subject }),
        ...(room !== undefined && { room }),
        ...(startTime && { startTime }),
        ...(endTime && { endTime }),
        updatedAt: new Date().toISOString(),
      };

      await docRef.update(updates);

      const updated = { id, ...docSnap.data(), ...updates };
      return res.json({ success: true, message: 'Period updated', data: updated });
    } catch (error) {
      console.error('PUT timetable/:id error:', error);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
  }
);

/* ──────────────────────────────────────────────────────────────
   DELETE /api/timetable/:id   (Admin / Staff only)
────────────────────────────────────────────────────────────── */
router.delete(
  '/timetable/:id',
  authenticate,
  authorize('admin', 'staff'),
  async (req, res) => {
    try {
      const { id } = req.params;
      const db = getFirestore();
      const docRef = db.collection(COLLECTION).doc(id);
      const docSnap = await docRef.get();

      if (!docSnap.exists) {
        return res.status(404).json({ success: false, message: 'Period not found' });
      }

      await docRef.delete();
      return res.json({ success: true, message: 'Period deleted' });
    } catch (error) {
      console.error('DELETE timetable/:id error:', error);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
  }
);

module.exports = router;
