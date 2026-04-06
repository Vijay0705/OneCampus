// ✅ FIXED — materials.js routes
const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { authenticate } = require('../middleware/auth');
const { uploadMaterial, getMaterials, deleteMaterial, downloadMaterial } = require('../controllers/materialController');

// ✅ FIXED — Upload any file type (not just PDF)
router.post('/', authenticate, upload.single('file'), uploadMaterial);

// ✅ FIXED — Get files; type is optional (returns all if not provided)
router.get('/', authenticate, getMaterials);

// ✅ FIXED — Get signed download URL
router.get('/download', authenticate, downloadMaterial);

// ✅ FIXED — Delete by id only (type no longer in path)
router.delete('/:id', authenticate, deleteMaterial);

module.exports = router;
