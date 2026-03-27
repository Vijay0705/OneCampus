const { getRealtimeDb } = require('../config/firebase');

const updateLocation = async (req, res) => {
  const { bus_id, latitude, longitude } = req.body;

  const db = getRealtimeDb();
  const ref = db.ref(`locations/${bus_id}`);

  const prev = (await ref.once('value')).val();

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

  res.json(data);
};

module.exports = { updateLocation };