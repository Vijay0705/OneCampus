const express = require('express');
const router = express.Router();
const { getFirestore, getRealtimeDb } = require('../config/firebase');

// 🔄 UPDATE LOCATION
const updateLocation = async (req, res) => {
  try {
    const { bus_id, latitude, longitude } = req.body;

    const db = getRealtimeDb();
    const ref = db.ref(`locations/${bus_id}`);

    const prev = (await ref.once('value')).val();

    // 🚫 Prevent fake jumps
    if (prev) {
      const diff = Math.abs(prev.latitude - latitude) + Math.abs(prev.longitude - longitude);
      if (diff > 0.5) {
        return res.status(400).json({ message: "Fake GPS detected" });
      }
    }

    const data = {
      bus_id,
      latitude,
      longitude,
      updatedAt: new Date().toISOString()
    };

    await ref.set(data);

    res.json({ success: true, data });

  } catch (err) {
    res.status(500).json({ message: "Failed to update location" });
  }
};

// 🚌 GET ALL BUSES
const getAllBuses = async (req, res) => {
  try {
    const db = getFirestore();
    const snapshot = await db.collection('buses').get();

    const buses = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ success: true, data: { buses } });

  } catch {
    res.status(500).json({ message: "Error fetching buses" });
  }
};

// ➕ CREATE BUS (ADMIN)
const createBus = async (req, res) => {
  try {
    const db = getFirestore();
    const { bus_number, route_name, capacity } = req.body;

    const ref = db.collection('buses').doc();

    await ref.set({
      id: ref.id,
      bus_number,
      route_name,
      capacity: capacity || 50,
      createdAt: new Date().toISOString()
    });

    res.json({ message: "Bus created" });

  } catch {
    res.status(500).json({ message: "Error creating bus" });
  }
};

// 📅 CREATE SCHEDULE
const createSchedule = async (req, res) => {
  try {
    const db = getFirestore();
    const { bus_id, date, stops } = req.body;

    const ref = db.collection('schedules').doc();

    await ref.set({
      id: ref.id,
      bus_id,
      date,
      stops,
      createdAt: new Date().toISOString()
    });

    res.json({ message: "Schedule created" });

  } catch {
    res.status(500).json({ message: "Error creating schedule" });
  }
};

// 📅 GET SCHEDULES
const getSchedules = async (req, res) => {
  try {
    const db = getFirestore();
    const { date } = req.query;

    const snapshot = await db.collection('schedules')
      .where('date', '==', date)
      .get();

    const schedules = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ success: true, data: { schedules } });

  } catch {
    res.status(500).json({ message: "Error fetching schedules" });
  }
};

// 📍 GET BUS LOCATION
const getBusLocation = async (req, res) => {
  try {
    const db = getRealtimeDb();
    const snapshot = await db.ref(`locations/${req.params.bus_id}`).once('value');

    const location = snapshot.val();

    if (!location) {
      return res.status(404).json({ message: "No location found" });
    }

    // ⏱️ Offline detection
    const last = new Date(location.updatedAt).getTime();
    const now = Date.now();

    const isOffline = now - last > 30000;

    res.json({
      success: true,
      data: { location: { ...location, isOffline } }
    });

  } catch {
    res.status(500).json({ message: "Error fetching location" });
  }
};

module.exports = {
  updateLocation,
  getAllBuses,
  createBus,
  createSchedule,
  getSchedules,
  getBusLocation
};

module.exports = router;