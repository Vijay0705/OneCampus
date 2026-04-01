const express = require('express');
const { body, param } = require('express-validator');
const {
  createAnnouncement,
  getAnnouncements,
  updateAnnouncement,
  deleteAnnouncement,
} = require('../controllers/announcementController');

const { authenticate, authorize } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// ✅ 1. GET ALL (must come FIRST)
router.get('/', authenticate, getAnnouncements);

// ✅ 2. GET SINGLE (must come AFTER '/')
router.get(
  '/:id',
  authenticate,
  [
    param('id').notEmpty().withMessage('Announcement id is required'),
  ],
  validate,
  async (req, res) => {
    try {
      const db = require('../config/firebase');

      const doc = await db
        .collection('announcements')
        .doc(req.params.id)
        .get();

      if (!doc.exists) {
        return res.status(404).json({
          message: 'Announcement not found',
        });
      }

      res.json({
        id: doc.id,
        ...doc.data(),
      });
    } catch (error) {
      console.error('Error fetching announcement:', error);
      res.status(500).json({
        message: 'Server error',
      });
    }
  }
);

router.post(
  '/',
  authenticate,
  authorize('admin', 'staff'),
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('description').trim().notEmpty().withMessage('Description is required'),
    body('priority').optional().isIn(['low', 'medium', 'high']),
    body('department').optional().isString(),
    body('isPinned').optional().isBoolean(),
  ],
  validate,
  createAnnouncement,
);

router.put(
  '/:id',
  authenticate,
  authorize('admin', 'staff'),
  [
    param('id').notEmpty().withMessage('Announcement id is required'),
    body('title').optional().isString(),
    body('description').optional().isString(),
    body('priority').optional().isIn(['low', 'medium', 'high']),
    body('department').optional().isString(),
    body('isPinned').optional().isBoolean(),
  ],
  validate,
  updateAnnouncement,
);

router.delete(
  '/:id',
  authenticate,
  authorize('admin', 'staff'),
  [param('id').notEmpty().withMessage('Announcement id is required')],
  validate,
  deleteAnnouncement,
);

module.exports = router;