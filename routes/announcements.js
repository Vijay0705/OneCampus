const express = require('express');
const router = express.Router();

const {
  createAnnouncement,
  getAnnouncements
} = require('../controllers/announcementController');

const { authenticate, authorize } = require('../middleware/auth');

// GET all
router.get('/', getAnnouncements);

// POST (Admin only)
router.post('/', authenticate, authorize('admin', 'staff'), createAnnouncement);

module.exports = router;