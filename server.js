require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const { initFirebase } = require('./config/firebase');

// 🔐 Existing routes
const authRoutes = require('./routes/auth');
const trackingRoutes = require('./routes/tracking');
const canteenRoutes = require('./routes/canteen');
const marketplaceRoutes = require('./routes/marketplace');
const timetableRoutes = require('./routes/timetableRoutes');


// 🆕 NEW routes
const announcementRoutes = require('./routes/announcements');
const materialRoutes = require('./routes/materials');

const { errorHandler, notFound } = require('./middleware/errorHandler');

// 🔥 Initialize Firebase
try {
  initFirebase();
} catch (err) {
  console.error('\n❌ STARTUP FAILED:', err.message, '\n');
  process.exit(1);
}

const app = express();

// 🔐 Security
app.use(helmet());

// 🌐 CORS (works for Flutter, Web, Postman)
app.use(cors({
  origin: true,
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

// 📦 Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 📊 Logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined'));
}

// ❤️ Health check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'OneCampus API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// ✅ ADD THIS HERE 👇
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to OneCampus API 🚀'
  });
});


// 🚀 ROUTES
app.use('/api/auth', authRoutes);
app.use('/api/tracking', trackingRoutes);
app.use('/api/canteen', canteenRoutes);
app.use('/api/marketplace', marketplaceRoutes);

// 🆕 NEW FEATURES
app.use('/api/announcements', announcementRoutes);
app.use('/api/materials', materialRoutes);
app.use('/api/timetable', timetableRoutes); // ✅ FIXED




// ❌ 404 handler
app.use(notFound);

// ⚠️ Global error handler
app.use(errorHandler);


// 🌐 Server start
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 OneCampus Backend running on port ${PORT}`);
  console.log(`📡 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Health check: http://127.0.0.1:${PORT}/health`);
});

module.exports = app;