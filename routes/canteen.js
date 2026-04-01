const express = require('express');
const { body, param } = require('express-validator');
const {
  addItem,
  getTodayItems,
  placeOrder,
  getOrders,
  updateOrderStatus,
  removeItem,
} = require('../controllers/canteenController');
const { authenticate, authorize } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

router.post(
  '/add-item',
  authenticate,
  authorize('admin', 'staff'),
  [
    body('name').notEmpty().withMessage('name is required'),
    body('price').isFloat({ min: 0 }).withMessage('Valid price required'),
    body('quantity').isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
    body('category').optional().isString(),
  ],
  validate,
  addItem
);

router.get('/today-items', authenticate, getTodayItems);

router.post(
  '/order',
  authenticate,
  authorize('student', 'staff'),
  [
    body('items').isArray({ min: 1 }).withMessage('items must be a non-empty array'),
    body('items.*.item_id').notEmpty().withMessage('Each item must have item_id'),
    body('items.*.quantity').isInt({ min: 1 }).withMessage('Each item must have quantity >= 1'),
  ],
  validate,
  placeOrder
);

router.get('/orders', authenticate, getOrders);

router.patch(
  '/order/:id/status',
  authenticate,
  authorize('admin', 'staff', 'student'),
  [
    param('id').notEmpty(),
    body('status').isIn(['pending', 'preparing', 'ready', 'completed', 'cancelled']),
  ],
  validate,
  updateOrderStatus
);

router.delete(
  '/item/:id',
  authenticate,
  authorize('admin'),
  [param('id').notEmpty()],
  validate,
  removeItem
);

module.exports = router;
