const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getFirestore } = require('../config/firebase');

// 🔐 Generate JWT with role (VERY IMPORTANT)
const generateToken = (uid, role) => {
  return jwt.sign({ uid, role }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });
};

// 📝 REGISTER
const register = async (req, res) => {
  try {
    const { name, email, password, role, studentId, dept, year } = req.body;
    const db = getFirestore();

    // ✅ Basic validation
    if (!name || !email || !password) {
      return res.status(400).json({ message: "Name, email, password required" });
    }

    // ✅ Check duplicate email
    const existing = await db.collection('users')
      .where('email', '==', email.toLowerCase())
      .get();

    if (!existing.empty) {
      return res.status(409).json({ message: "Email already exists" });
    }

    // 🔐 Hash password
    const hashed = await bcrypt.hash(password, 12);

    const userRef = db.collection('users').doc();

    const user = {
      uid: userRef.id,
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password: hashed,
      role: role || 'student', // default role
      studentId: studentId || null,
      dept: dept || null,
      year: year || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await userRef.set(user);

    // 🔑 Generate token
    const token = generateToken(user.uid, user.role);

    // ❌ Remove password from response
    delete user.password;

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: { user, token },
    });

  } catch (err) {
    console.error("Register error:", err);
    res.status(500).json({ message: "Register failed" });
  }
};

// 🔓 LOGIN
const login = async (req, res) => {
  try {
    const db = getFirestore();
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email & password required" });
    }

    const snap = await db.collection('users')
      .where('email', '==', email.toLowerCase())
      .limit(1)
      .get();

    if (snap.empty) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const user = snap.docs[0].data();

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const token = generateToken(user.uid, user.role);

    delete user.password;

    res.json({
      success: true,
      message: "Login successful",
      data: { user, token },
    });

  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Login failed" });
  }
};

// 👤 GET PROFILE (FIXES YOUR ERROR 🔥)
const getProfile = async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const { password, ...safeUser } = req.user;

    res.json({
      success: true,
      data: { user: safeUser },
    });

  } catch (err) {
    console.error("Profile error:", err);
    res.status(500).json({ message: "Failed to fetch profile" });
  }
};

// ✏️ UPDATE PROFILE
const updateProfile = async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const { name, phone, email, dept, year } = req.body;
    const db = getFirestore();
    const userRef = db.collection('users').doc(req.user.uid);

    const updateData = { updatedAt: new Date().toISOString() };
    if (name) updateData.name = name.trim();
    if (phone !== undefined) updateData.phone = phone;
    if (email) updateData.email = email.toLowerCase().trim();
    if (dept !== undefined) updateData.dept = dept;
    if (year !== undefined) updateData.year = year;

    await userRef.update(updateData);

    // Fetch updated user
    const updatedUserDoc = await userRef.get();
    const { password, ...safeUser } = updatedUserDoc.data();

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: { user: safeUser },
    });
  } catch (err) {
    console.error("Update profile error:", err);
    res.status(500).json({ message: "Failed to update profile" });
  }
};

// 🚪 LOGOUT (OPTIONAL)
const logout = async (req, res) => {
  // JWT is stateless → just respond success
  res.json({ success: true, message: "Logged out successfully" });
};

module.exports = {
  register,
  login,
  getProfile,   // 🔥 IMPORTANT FIX
  updateProfile,
  logout,
};