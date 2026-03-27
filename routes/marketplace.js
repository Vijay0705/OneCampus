const express = require('express');
const { body, param, query } = require('express-validator');
const {
  addProduct,
  getProducts,
  getProductById,
  markSold,
  deleteProduct,
  getMyProducts,
} = require('../controllers/marketplaceController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

router.post(
  '/add-product',
  authenticate,
  [
    body('title').notEmpty().withMessage('title is required'),
    body('price').isFloat({ min: 0 }).withMessage('Valid price required'),
    body('category').notEmpty().withMessage('category is required'),
    body('condition').optional().isIn(['new', 'like-new', 'used', 'poor']),
  ],
  validate,
  addProduct
);

router.get('/products', authenticate, getProducts);
router.get('/my-products', authenticate, getMyProducts);
router.get('/products/:id', authenticate, [param('id').notEmpty()], validate, getProductById);
router.patch('/mark-sold/:id', authenticate, [param('id').notEmpty()], validate, markSold);
router.delete('/products/:id', authenticate, [param('id').notEmpty()], validate, deleteProduct);

module.exports = router;
