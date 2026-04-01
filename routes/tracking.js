const express = require('express');
const { body, param, query } = require('express-validator');
const {
  updateLocation,
  getAllBuses,
  createBus,
  updateBus,
  deleteBus,
  createSchedule,
  updateSchedule,
  deleteSchedule,
  getSchedules,
  getBusLocation,
  getAllBusLocations,
} = require('../controllers/trackingController');
const { authenticate, authorize } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

router.post(
  '/location',
  authenticate,
  [
    body('bus_id').notEmpty().withMessage('bus_id is required'),
    body('latitude').isFloat().withMessage('latitude must be a number'),
    body('longitude').isFloat().withMessage('longitude must be a number'),
  ],
  validate,
  updateLocation,
);

router.get('/location', authenticate, getAllBusLocations);

router.get(
  '/location/:bus_id',
  authenticate,
  [param('bus_id').notEmpty().withMessage('bus id is required')],
  validate,
  getBusLocation,
);

router.get('/buses', authenticate, getAllBuses);

router.post(
  '/buses',
  authenticate,
  authorize('admin', 'staff'),
  [
    body('bus_number').notEmpty().withMessage('bus_number is required'),
    body('route_name').notEmpty().withMessage('route_name is required'),
    body('capacity').optional().isInt({ min: 1 }),
    body('is_active').optional().isBoolean(),
  ],
  validate,
  createBus,
);

router.put(
  '/buses/:id',
  authenticate,
  authorize('admin', 'staff'),
  [
    param('id').notEmpty(),
    body('capacity').optional().isInt({ min: 1 }),
    body('is_active').optional().isBoolean(),
  ],
  validate,
  updateBus,
);

router.delete(
  '/buses/:id',
  authenticate,
  authorize('admin', 'staff'),
  [param('id').notEmpty()],
  validate,
  deleteBus,
);

router.get(
  '/schedules',
  authenticate,
  [query('date').optional().isString()],
  validate,
  getSchedules,
);

router.post(
  '/schedules',
  authenticate,
  authorize('admin', 'staff'),
  [
    body('bus_id').notEmpty().withMessage('bus_id is required'),
    body('date').notEmpty().withMessage('date is required'),
    body('stops').optional().isArray(),
    body('departure_time').optional().isString(),
    body('arrival_time').optional().isString(),
  ],
  validate,
  createSchedule,
);

router.put(
  '/schedules/:id',
  authenticate,
  authorize('admin', 'staff'),
  [
    param('id').notEmpty(),
    body('stops').optional().isArray(),
    body('departure_time').optional().isString(),
    body('arrival_time').optional().isString(),
  ],
  validate,
  updateSchedule,
);

router.delete(
  '/schedules/:id',
  authenticate,
  authorize('admin', 'staff'),
  [param('id').notEmpty()],
  validate,
  deleteSchedule,
);

module.exports = router;