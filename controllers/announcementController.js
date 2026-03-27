const { getFirestore } = require('../config/firebase');

// CREATE announcement
exports.createAnnouncement = async (req, res) => {
  try {
    const db = getFirestore();

    const { title, description, priority, department } = req.body;

    if (!title || !description) {
      return res.status(400).json({ error: "Title and description are required" });
    }

    const newAnnouncement = {
      title,
      description,
      priority: priority || "low",
      department: department || "ALL",
      createdBy: req.user?.id || "admin",
      createdAt: new Date().toISOString(),
      isPinned: false
    };

    const docRef = await db.collection('announcements').add(newAnnouncement);

    res.status(201).json({
      success: true,
      message: "Announcement created",
      id: docRef.id
    });

  } catch (err) {
    console.error("❌ createAnnouncement error:", err);
    res.status(500).json({ error: err.message });
  }
};

// GET all announcements
exports.getAnnouncements = async (req, res) => {
  try {
    const db = getFirestore();

    const snapshot = await db
      .collection('announcements')
      .orderBy('createdAt', 'desc')
      .get();

    const announcements = snapshot.docs.map(doc => {
      const data = doc.data();
      // Normalize createdAt: convert Firestore Timestamp → ISO string if needed
      if (data.createdAt && typeof data.createdAt.toDate === 'function') {
        data.createdAt = data.createdAt.toDate().toISOString();
      }
      return { id: doc.id, ...data };
    });

    res.json(announcements);

  } catch (err) {
    console.error("❌ getAnnouncements error:", err);
    res.status(500).json({ error: err.message });
  }
};