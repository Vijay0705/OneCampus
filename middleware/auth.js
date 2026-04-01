const jwt = require('jsonwebtoken');
const { getFirestore } = require('../config/firebase');

const authenticate = async (req, res, next) => {
  try {
    const header = req.headers.authorization;

    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = header.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const db = getFirestore();
    const userDoc = await db.collection('users').doc(decoded.uid).get();

    if (!userDoc.exists) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    const userData = userDoc.data();
    req.user = {
      uid: decoded.uid,
      id: decoded.uid,
      role: userData.role || decoded.role || 'student',
      ...userData,
    };

    return next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

const authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  return next();
};

module.exports = { authenticate, authorize };