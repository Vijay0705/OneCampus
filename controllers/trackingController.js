const { getFirestore, getRealtimeDb } = require('../config/firebase');

const getBusRef = (id) => getFirestore().collection('buses').doc(id);

const updateLocation = async (req, res) => {
  try {
    const { bus_id, latitude, longitude } = req.body;

    if (!bus_id || latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'bus_id, latitude, longitude are required',
      });
    }

    const lat = Number(latitude);
    const lng = Number(longitude);

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ success: false, message: 'Invalid coordinates' });
    }

    const db = getRealtimeDb();
    const ref = db.ref(`locations/${bus_id}`);

    const prev = (await ref.once('value')).val();

    if (prev) {
      const diff = Math.abs(prev.latitude - lat) + Math.abs(prev.longitude - lng);
      if (diff > 0.8) {
        return res.status(400).json({ success: false, message: 'Fake GPS detected' });
      }
    }

    const now = new Date().toISOString();

    const data = {
      bus_id,
      latitude: lat,
      longitude: lng,
      timestamp: now,
      updatedAt: now,
      source: req.body.source || 'mobile',
    };

    await ref.set(data);

    return res.json({ success: true, data });
  } catch (error) {
    console.error('updateLocation error:', error);
    return res.status(500).json({ success: false, message: 'Failed to update location' });
  }
};

const getAllBuses = async (req, res) => {
  try {
    const db = getFirestore();
    const snapshot = await db.collection('buses').get();

    const buses = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => (a.bus_number || '').localeCompare(b.bus_number || ''));

    return res.json({ success: true, data: { buses } });
  } catch (error) {
    console.error('getAllBuses error:', error);
    return res.status(500).json({ success: false, message: 'Error fetching buses' });
  }
};

const createBus = async (req, res) => {
  try {
    const db = getFirestore();
    const { bus_number, route_name, capacity, is_active } = req.body;

    if (!bus_number || !route_name) {
      return res
        .status(400)
        .json({ success: false, message: 'bus_number and route_name are required' });
    }

    const ref = db.collection('buses').doc();
    const now = new Date().toISOString();

    const bus = {
      id: ref.id,
      bus_number: String(bus_number).trim(),
      route_name: String(route_name).trim(),
      capacity: Number(capacity) > 0 ? Number(capacity) : 50,
      is_active: is_active === undefined ? true : Boolean(is_active),
      createdBy: req.user.uid,
      createdAt: now,
      updatedAt: now,
    };

    await ref.set(bus);

    return res.status(201).json({ success: true, message: 'Bus created', data: { bus } });
  } catch (error) {
    console.error('createBus error:', error);
    return res.status(500).json({ success: false, message: 'Error creating bus' });
  }
};

const updateBus = async (req, res) => {
  try {
    const ref = getBusRef(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Bus not found' });
    }

    const { bus_number, route_name, capacity, is_active } = req.body;

    const updateData = { updatedAt: new Date().toISOString() };
    if (bus_number !== undefined) updateData.bus_number = String(bus_number).trim();
    if (route_name !== undefined) updateData.route_name = String(route_name).trim();
    if (capacity !== undefined) updateData.capacity = Number(capacity) > 0 ? Number(capacity) : 50;
    if (is_active !== undefined) updateData.is_active = Boolean(is_active);

    await ref.update(updateData);

    return res.json({ success: true, message: 'Bus updated' });
  } catch (error) {
    console.error('updateBus error:', error);
    return res.status(500).json({ success: false, message: 'Error updating bus' });
  }
};

const deleteBus = async (req, res) => {
  try {
    const db = getFirestore();
    const busId = req.params.id;
    const ref = db.collection('buses').doc(busId);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Bus not found' });
    }

    await ref.delete();

    const schedules = await db.collection('schedules').where('bus_id', '==', busId).get();
    if (!schedules.empty) {
      const batch = db.batch();
      schedules.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }

    await getRealtimeDb().ref(`locations/${busId}`).remove();

    return res.json({ success: true, message: 'Bus deleted' });
  } catch (error) {
    console.error('deleteBus error:', error);
    return res.status(500).json({ success: false, message: 'Error deleting bus' });
  }
};

const createSchedule = async (req, res) => {
  try {
    const db = getFirestore();
    const { bus_id, date, stops, departure_time, arrival_time } = req.body;

    if (!bus_id || !date) {
      return res.status(400).json({ success: false, message: 'bus_id and date are required' });
    }

    const busDoc = await db.collection('buses').doc(bus_id).get();
    if (!busDoc.exists) {
      return res.status(404).json({ success: false, message: 'Bus not found' });
    }

    const ref = db.collection('schedules').doc();

    const schedule = {
      id: ref.id,
      bus_id,
      date,
      stops: Array.isArray(stops) ? stops : [],
      departure_time: departure_time || '',
      arrival_time: arrival_time || '',
      createdBy: req.user.uid,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await ref.set(schedule);

    return res.status(201).json({
      success: true,
      message: 'Schedule created',
      data: { schedule },
    });
  } catch (error) {
    console.error('createSchedule error:', error);
    return res.status(500).json({ success: false, message: 'Error creating schedule' });
  }
};

const updateSchedule = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('schedules').doc(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Schedule not found' });
    }

    const { date, stops, departure_time, arrival_time } = req.body;

    const updateData = {
      updatedAt: new Date().toISOString(),
    };

    if (date !== undefined) updateData.date = date;
    if (stops !== undefined) updateData.stops = Array.isArray(stops) ? stops : [];
    if (departure_time !== undefined) updateData.departure_time = departure_time;
    if (arrival_time !== undefined) updateData.arrival_time = arrival_time;

    await ref.update(updateData);

    return res.json({ success: true, message: 'Schedule updated' });
  } catch (error) {
    console.error('updateSchedule error:', error);
    return res.status(500).json({ success: false, message: 'Error updating schedule' });
  }
};

const deleteSchedule = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('schedules').doc(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Schedule not found' });
    }

    await ref.delete();

    return res.json({ success: true, message: 'Schedule deleted' });
  } catch (error) {
    console.error('deleteSchedule error:', error);
    return res.status(500).json({ success: false, message: 'Error deleting schedule' });
  }
};

const getSchedules = async (req, res) => {
  try {
    const db = getFirestore();
    const { date } = req.query;

    let query = db.collection('schedules');
    if (date) {
      query = query.where('date', '==', date);
    }

    const snapshot = await query.get();

    const schedules = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => {
        if (a.date === b.date) {
          return (a.departure_time || '').localeCompare(b.departure_time || '');
        }
        return a.date < b.date ? -1 : 1;
      });

    return res.json({ success: true, data: { schedules } });
  } catch (error) {
    console.error('getSchedules error:', error);
    return res.status(500).json({ success: false, message: 'Error fetching schedules' });
  }
};

const getBusLocation = async (req, res) => {
  try {
    const db = getRealtimeDb();
    const snapshot = await db.ref(`locations/${req.params.bus_id}`).once('value');

    const location = snapshot.val();

    if (!location) {
      return res.status(404).json({ success: false, message: 'No location found' });
    }

    const last = new Date(location.updatedAt || location.timestamp || 0).getTime();
    const now = Date.now();
    const isOffline = Number.isFinite(last) ? now - last > 30000 : true;

    return res.json({
      success: true,
      data: { location: { ...location, isOffline } },
    });
  } catch (error) {
    console.error('getBusLocation error:', error);
    return res.status(500).json({ success: false, message: 'Error fetching location' });
  }
};

const getAllBusLocations = async (req, res) => {
  try {
    const snapshot = await getRealtimeDb().ref('locations').once('value');
    const data = snapshot.val() || {};

    return res.json({ success: true, data: { locations: data } });
  } catch (error) {
    console.error('getAllBusLocations error:', error);
    return res.status(500).json({ success: false, message: 'Error fetching locations' });
  }
};

module.exports = {
  updateLocation,
  getAllBuses,
  createBus,
  updateBus,
  deleteBus,
  createSchedule,
  updateSchedule,
  deleteSchedule,
  getSchedules,
  getBusLocation,
  getAllBusLocations,
};