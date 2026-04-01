const express = require('express');
const router = express.Router();

const upload = require('../middleware/upload');
const { authenticate } = require('../middleware/auth');

const {
  uploadMaterial,
  getMaterials,
} = require('../controllers/materialController');

router.post('/', authenticate, upload.single('file'), uploadMaterial);
router.get('/', authenticate, getMaterials);

module.exports = router;