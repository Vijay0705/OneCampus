const { getFirestore, getStorageBucket } = require('../config/firebase');

const uploadMaterial = async (req, res) => {
  try {
    const db = getFirestore();
    const bucket = getStorageBucket();
    const file = req.file;

    if (!file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    if (file.mimetype !== 'application/pdf') {
      return res.status(400).json({ success: false, message: 'Only PDF files allowed' });
    }

    const { title, subject, semester, type } = req.body;

    if (!title || !subject) {
      return res.status(400).json({
        success: false,
        message: 'Title and subject are required',
      });
    }

    const fileName = `materials/${Date.now()}_${file.originalname}`;
    const fileUpload = bucket.file(fileName);

    await fileUpload.save(file.buffer, {
      metadata: {
        contentType: file.mimetype,
        cacheControl: 'public,max-age=3600',
      },
    });

    const fileUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

    const ref = db.collection('materials').doc();
    const newMaterial = {
      id: ref.id,
      title,
      subject,
      type: type || 'notes',
      semester: semester || 'N/A',
      fileUrl,
      uploadedBy: req.user?.uid || req.user?.id || 'unknown',
      uploaderName: req.user?.name || 'Unknown',
      createdAt: new Date().toISOString(),
      downloads: 0,
      likes: 0,
    };

    await ref.set(newMaterial);

    return res.status(201).json({
      success: true,
      message: 'File uploaded successfully',
      data: { material: newMaterial },
    });
  } catch (err) {
    console.error('uploadMaterial error:', err);
    return res.status(500).json({ success: false, message: 'Upload failed' });
  }
};

const getMaterials = async (req, res) => {
  try {
    const db = getFirestore();

    const snapshot = await db.collection('materials').orderBy('createdAt', 'desc').get();

    const materials = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.json({ success: true, data: materials });
  } catch (err) {
    console.error('getMaterials error:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch materials' });
  }
};

module.exports = {
  uploadMaterial,
  getMaterials,
};