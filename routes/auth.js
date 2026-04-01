const express = require('express');
const { body } = require('express-validator');
const {
  register,
  login,
  getProfile,
  updateProfile,
  saveDeviceToken,
  removeDeviceToken,
  logout,
} = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

router.post(
  '/register',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('role').optional().isIn(['student', 'admin', 'staff']).withMessage('Invalid role'),
  ],
  validate,
  register,
);

router.post(
  '/login',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  validate,
  login,
);

router.get('/profile', authenticate, getProfile);

router.put(
  '/profile',
  authenticate,
  [
    body('name').optional().isString(),
    body('email').optional().isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('phone').optional().isString(),
    body('dept').optional().isString(),
    body('year').optional(),
    body('studentId').optional().isString(),
  ],
  validate,
  updateProfile,
);

router.post(
  '/device-token',
  authenticate,
  [
    body('token').notEmpty().withMessage('Device token is required'),
    body('platform').optional().isIn(['android', 'ios', 'web', 'macos', 'windows', 'linux']),
  ],
  validate,
  saveDeviceToken,
);

router.delete(
  '/device-token',
  authenticate,
  [body('token').notEmpty().withMessage('Device token is required')],
  validate,
  removeDeviceToken,
);

router.post('/logout', authenticate, logout);

module.exports = router;