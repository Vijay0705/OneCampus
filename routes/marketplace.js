const express = require('express');
const { body, param } = require('express-validator');
const {
  addProduct,
  getProducts,
  getProductById,
  updateProduct,
  updateProductStatus,
  markSold,
  deleteProduct,
  getMyProducts,
} = require('../controllers/marketplaceController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const upload = require('../middleware/upload');

const router = express.Router();

router.post(
  '/add-product',
  authenticate,
  upload.single('image'),
  [
    body('title').notEmpty().withMessage('title is required'),
    body('price').isFloat({ min: 0 }).withMessage('Valid price required'),
    body('category').optional().isString(),
    body('condition').optional().isIn(['new', 'like-new', 'used', 'poor']),
  ],
  validate,
  addProduct,
);

router.get('/products', authenticate, getProducts);
router.get('/my-products', authenticate, getMyProducts);
router.get('/products/:id', authenticate, [param('id').notEmpty()], validate, getProductById);

router.put(
  '/products/:id',
  authenticate,
  upload.single('image'),
  [
    param('id').notEmpty(),
    body('price').optional().isFloat({ min: 0 }).withMessage('Valid price required'),
    body('condition').optional().isIn(['new', 'like-new', 'used', 'poor']),
  ],
  validate,
  updateProduct,
);

router.patch('/mark-sold/:id', authenticate, [param('id').notEmpty()], validate, markSold);

router.patch(
  '/products/:id/status',
  authenticate,
  [
    param('id').notEmpty(),
    body('status').isIn(['active', 'sold']).withMessage('Invalid status'),
  ],
  validate,
  updateProductStatus,
);

router.delete('/products/:id', authenticate, [param('id').notEmpty()], validate, deleteProduct);

module.exports = router;