const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { getFirestore } = require('../config/firebase');

const ALLOWED_ROLES = ['student', 'admin', 'staff'];

const normalizeRole = (role) => {
  if (!role) return 'student';
  const normalized = String(role).toLowerCase();
  return ALLOWED_ROLES.includes(normalized) ? normalized : 'student';
};

const generateToken = (uid, role) => {
  return jwt.sign({ uid, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

const withoutPassword = (user) => {
  if (!user) return user;
  const { password, ...safeUser } = user;
  return safeUser;
};

const register = async (req, res) => {
  try {
    const { name, email, password, role, studentId, dept, year } = req.body;
    const db = getFirestore();

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, and password are required',
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const existing = await db
      .collection('users')
      .where('email', '==', normalizedEmail)
      .limit(1)
      .get();

    if (!existing.empty) {
      return res.status(409).json({
        success: false,
        message: 'Email already exists',
      });
    }

    const hashed = await bcrypt.hash(password, 12);
    const userRef = db.collection('users').doc();

    const user = {
      uid: userRef.id,
      name: name.trim(),
      email: normalizedEmail,
      password: hashed,
      role: normalizeRole(role),
      studentId: studentId || null,
      phone: null,
      dept: dept || null,
      year: year || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await userRef.set(user);

    const token = generateToken(user.uid, user.role);

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: withoutPassword(user),
        token,
      },
    });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ success: false, message: 'Register failed' });
  }
};

const login = async (req, res) => {
  try {
    const db = getFirestore();
    const { email, password } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'Email and password are required' });
    }

    const normalizedEmail = email.toLowerCase().trim();

    const snap = await db
      .collection('users')
      .where('email', '==', normalizedEmail)
      .limit(1)
      .get();

    if (snap.empty) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid email or password' });
    }

    const user = snap.docs[0].data();

    const match = await bcrypt.compare(password, user.password || '');
    if (!match) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid email or password' });
    }

    const normalizedRole = normalizeRole(user.role);
    if (normalizedRole !== user.role) {
      await db.collection('users').doc(user.uid).update({ role: normalizedRole });
      user.role = normalizedRole;
    }

    const token = generateToken(user.uid, user.role);

    return res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: withoutPassword(user),
        token,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ success: false, message: 'Login failed' });
  }
};

const getProfile = async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    return res.json({
      success: true,
      data: { user: withoutPassword(req.user) },
    });
  } catch (err) {
    console.error('Profile error:', err);
    return res
      .status(500)
      .json({ success: false, message: 'Failed to fetch profile' });
  }
};

const updateProfile = async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const { name, phone, email, dept, year, studentId } = req.body;
    const db = getFirestore();
    const userRef = db.collection('users').doc(req.user.uid);

    const updateData = { updatedAt: new Date().toISOString() };

    if (name !== undefined) updateData.name = String(name).trim();
    if (phone !== undefined) updateData.phone = phone || null;
    if (dept !== undefined) updateData.dept = dept || null;
    if (year !== undefined) updateData.year = year || null;
    if (studentId !== undefined) updateData.studentId = studentId || null;

    if (email !== undefined && String(email).trim().length > 0) {
      const normalizedEmail = String(email).toLowerCase().trim();
      const existing = await db
        .collection('users')
        .where('email', '==', normalizedEmail)
        .limit(1)
        .get();

      if (!existing.empty && existing.docs[0].id !== req.user.uid) {
        return res
          .status(409)
          .json({ success: false, message: 'Email already exists' });
      }

      updateData.email = normalizedEmail;
    }

    await userRef.update(updateData);

    const updatedUserDoc = await userRef.get();

    return res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { user: withoutPassword(updatedUserDoc.data()) },
    });
  } catch (err) {
    console.error('Update profile error:', err);
    return res
      .status(500)
      .json({ success: false, message: 'Failed to update profile' });
  }
};

const saveDeviceToken = async (req, res) => {
  try {
    const { token, platform } = req.body;

    if (!token) {
      return res
        .status(400)
        .json({ success: false, message: 'Device token is required' });
    }

    const db = getFirestore();
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const docId = `${req.user.uid}_${tokenHash}`;
    const ref = db.collection('device_tokens').doc(docId);

    const now = new Date().toISOString();
    const existing = await ref.get();

    await ref.set(
      {
        uid: req.user.uid,
        role: req.user.role,
        token,
        platform: platform || 'unknown',
        createdAt: existing.exists
          ? existing.data().createdAt || now
          : now,
        updatedAt: now,
      },
      { merge: true },
    );

    return res.json({ success: true, message: 'Device token saved' });
  } catch (error) {
    console.error('saveDeviceToken error:', error);
    return res
      .status(500)
      .json({ success: false, message: 'Failed to save device token' });
  }
};

const removeDeviceToken = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res
        .status(400)
        .json({ success: false, message: 'Device token is required' });
    }

    const db = getFirestore();
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const docId = `${req.user.uid}_${tokenHash}`;

    await db.collection('device_tokens').doc(docId).delete();

    return res.json({ success: true, message: 'Device token removed' });
  } catch (error) {
    console.error('removeDeviceToken error:', error);
    return res
      .status(500)
      .json({ success: false, message: 'Failed to remove device token' });
  }
};

const logout = async (req, res) => {
  return res.json({ success: true, message: 'Logged out successfully' });
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  saveDeviceToken,
  removeDeviceToken,
  logout,
};