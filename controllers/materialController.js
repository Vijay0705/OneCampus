// ✅ FIXED — materialController.js
const { getFirestore } = require('../config/firebase');
const { uploadToR2, deleteFromR2, getDownloadUrl } = require('../services/r2Upload');
const path = require('path');

// ✅ ADDED — Derive MIME type from extension when not set by multer
const MIME_MAP = {
  pdf:  'application/pdf',
  doc:  'application/msword',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ppt:  'application/vnd.ms-powerpoint',
  pptx: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  xls:  'application/vnd.ms-excel',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  zip:  'application/zip',
  rar:  'application/x-rar-compressed',
  txt:  'text/plain',
  jpg:  'image/jpeg',
  jpeg: 'image/jpeg',
  png:  'image/png',
  gif:  'image/gif',
  mp4:  'video/mp4',
  mp3:  'audio/mpeg',
};

function resolveMime(file) {
  if (file.mimetype && file.mimetype !== 'application/octet-stream') return file.mimetype;
  const ext = path.extname(file.originalname).replace('.', '').toLowerCase();
  return MIME_MAP[ext] || 'application/octet-stream';
}

/* ──────────────────────────────────────────────────────────────
   POST /api/materials
   Multipart: file + { title, subject, type, semester }
   type: 'notes' | 'qp' | 'materials'
────────────────────────────────────────────────────────────── */
const uploadMaterial = async (req, res) => {
  try {
    const file = req.file;
    if (!file)
      return res.status(400).json({ success: false, message: 'No file uploaded' });

    const { title, subject, semester, type } = req.body;
    if (!title || !subject)
      return res.status(400).json({ success: false, message: 'Title and subject required' });

    // ✅ FIXED — resolve MIME before uploading
    file.mimetype = resolveMime(file);

    const folder = type || 'materials';

    // ✅ FIXED — upload to R2
    const fileUrl = await uploadToR2(file, folder);

    const db = getFirestore();
    const ref = db.collection('materials').doc(); // ✅ FIXED — always use 'materials' collection

    const newFile = {
      id:           ref.id,
      title,
      subject,
      type:         folder,
      semester:     semester || 'N/A',
      fileUrl,
      fileName:     file.originalname,
      fileSize:     file.size,
      mimeType:     file.mimetype,
      uploadedBy:   req.user?.uid || req.user?.id || 'unknown',
      uploaderName: req.user?.name || req.user?.displayName || 'Unknown',
      uploaderRole: req.user?.role || 'student',
      createdAt:    new Date().toISOString(),
      downloads:    0,
    };

    await ref.set(newFile);

    return res.status(201).json({
      success: true,
      message: 'File uploaded successfully',
      data: { file: newFile },
    });
  } catch (err) {
    console.error('uploadMaterial error:', err);
    return res.status(500).json({ success: false, message: 'Upload failed: ' + err.message });
  }
};

/* ──────────────────────────────────────────────────────────────
   GET /api/materials?type=notes&subject=DSA&semester=3
   ✅ FIXED — type is now OPTIONAL; returns all if omitted
────────────────────────────────────────────────────────────── */
const getMaterials = async (req, res) => {
  try {
    const { type, subject, semester } = req.query;

    const db = getFirestore();
    // ✅ FIXED — always query the 'materials' collection regardless of type
    let query = db.collection('materials').orderBy('createdAt', 'desc');

    if (type)     query = query.where('type', '==', type);
    if (subject)  query = query.where('subject', '==', subject);
    if (semester) query = query.where('semester', '==', semester);

    const snapshot = await query.get();
    const files = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    return res.json({ success: true, data: files });
  } catch (err) {
    console.error('getMaterials error:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch files' });
  }
};

/* ──────────────────────────────────────────────────────────────
   DELETE /api/materials/:id
   ✅ FIXED — uses unified 'materials' collection
────────────────────────────────────────────────────────────── */
const deleteMaterial = async (req, res) => {
  try {
    const { id } = req.params;
    if (!id) return res.status(400).json({ success: false, message: 'ID required' });

    const db = getFirestore();
    const docRef = db.collection('materials').doc(id);
    const docSnap = await docRef.get();

    if (!docSnap.exists)
      return res.status(404).json({ success: false, message: 'File not found' });

    const fileData = docSnap.data();

    // ✅ FIXED — ownership check
    if (fileData.uploadedBy !== req.user.id && fileData.uploadedBy !== req.user.uid && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized to delete this material' });
    }

    // ✅ FIXED — delete from R2 only if URL is present
    if (fileData.fileUrl) {
      await deleteFromR2(fileData.fileUrl).catch((e) =>
        console.warn('R2 delete warning:', e.message)
      );
    }

    await docRef.delete();
    return res.json({ success: true, message: 'File deleted successfully' });
  } catch (err) {
    console.error('deleteMaterial error:', err);
    return res.status(500).json({ success: false, message: 'Delete failed' });
  }
};

/* ──────────────────────────────────────────────────────────────
   GET /api/materials/download?key=...
   ✅ FIXED — Returns R2 signed URL
────────────────────────────────────────────────────────────── */
const downloadMaterial = async (req, res) => {
  try {
    const { key } = req.query;
    if (!key) return res.status(400).json({ success: false, message: 'File key required' });

    const signedUrl = await getDownloadUrl(key);
    if (!signedUrl) return res.status(500).json({ success: false, message: 'Failed to generate download link' });

    return res.json({ success: true, url: signedUrl });
  } catch (err) {
    console.error('downloadMaterial error:', err);
    return res.status(500).json({ success: false, error: 'Download failed' });
  }
};

module.exports = { uploadMaterial, getMaterials, deleteMaterial, downloadMaterial };
