const { getFirestore } = require('../config/firebase');
const admin = require('firebase-admin');

// UPLOAD material
exports.uploadMaterial = async (req, res) => {
  try {
    const db = getFirestore();
    const bucket = admin.storage().bucket(); // ✅ safe now (after init)

    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    // ✅ Only PDF allowed
    if (file.mimetype !== 'application/pdf') {
      return res.status(400).json({ error: "Only PDF files allowed" });
    }

    const fileName = `materials/${Date.now()}_${file.originalname}`;
    const fileUpload = bucket.file(fileName);

    const stream = fileUpload.createWriteStream({
      metadata: {
        contentType: file.mimetype,
      },
    });

    stream.end(file.buffer);

    stream.on('finish', async () => {
      const fileUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      const { title, subject, semester } = req.body;

      if (!title || !subject) {
        return res.status(400).json({ error: "Title and subject are required" });
      }

      const newMaterial = {
        title,
        subject,
        semester: semester || "N/A",
        fileUrl,
        uploadedBy: req.user?.id || "student",
        createdAt: new Date(),
        downloads: 0,
        likes: 0
      };

      const docRef = await db.collection('materials').add(newMaterial);

      res.status(201).json({
        success: true,
        message: "File uploaded successfully",
        id: docRef.id,
        fileUrl
      });
    });

    stream.on('error', (err) => {
      console.error("❌ Upload stream error:", err);
      res.status(500).json({ error: err.message });
    });

  } catch (err) {
    console.error("❌ uploadMaterial error:", err);
    res.status(500).json({ error: err.message });
  }
};

// GET all materials
exports.getMaterials = async (req, res) => {
  try {
    const db = getFirestore();

    const snapshot = await db
      .collection('materials')
      .orderBy('createdAt', 'desc')
      .get();

    const materials = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json(materials);

  } catch (err) {
    console.error("❌ getMaterials error:", err);
    res.status(500).json({ error: err.message });
  }
};