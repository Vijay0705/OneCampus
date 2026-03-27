const express = require('express');
const router = express.Router();

const upload = require('../middleware/upload');

const {
  uploadMaterial,
  getMaterials
} = require('../controllers/materialController');

// Upload PDF
router.post('/', upload.single('file'), uploadMaterial);

// Get all
router.get('/', getMaterials);

module.exports = router;