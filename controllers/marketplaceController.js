const { getFirestore } = require('../config/firebase');

// ➕ ADD PRODUCT
const addProduct = async (req, res) => {
  try {
    const db = getFirestore();

    const snapshot = await db.collection('products')
      .where('seller_id', '==', req.user.uid)
      .get();

    if (snapshot.size >= 5) {
      return res.status(400).json({ message: "Daily limit reached" });
    }

    const ref = db.collection('products').doc();

    await ref.set({
      id: ref.id,
      ...req.body,
      seller_id: req.user.uid,
      status: "active",
      createdAt: new Date().toISOString()
    });

    res.json({ message: "Product added" });

  } catch {
    res.status(500).json({ message: "Error adding product" });
  }
};

// 📋 GET ALL PRODUCTS (supports ?category=Books filtering)
const getProducts = async (req, res) => {
  try {
    const db = getFirestore();

    let query = db.collection('products').where('status', '==', 'active');

    const { category } = req.query;
    if (category && category !== 'All') {
      query = query.where('category', '==', category);
    }

    const snapshot = await query.get();

    const products = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ success: true, data: { products } });

  } catch {
    res.status(500).json({ message: "Error fetching products" });
  }
};

// 📦 GET SINGLE PRODUCT
const getProductById = async (req, res) => {
  try {
    const db = getFirestore();
    const doc = await db.collection('products').doc(req.params.id).get();

    if (!doc.exists) {
      return res.status(404).json({ message: "Product not found" });
    }

    res.json({ success: true, data: { product: doc.data() } });

  } catch {
    res.status(500).json({ message: "Error fetching product" });
  }
};

// 🏷️ MARK AS SOLD
const markSold = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('products').doc(req.params.id);
    const doc = await ref.get();

    const product = doc.data();

    if (product.seller_id !== req.user.uid && req.user.role !== 'admin') {
      return res.status(403).json({ message: "Not allowed" });
    }

    if (product.status === "sold") {
      return res.status(400).json({ message: "Already sold" });
    }

    await ref.update({ status: "sold" });

    res.json({ message: "Marked sold" });

  } catch {
    res.status(500).json({ message: "Error updating product" });
  }
};

// ❌ DELETE PRODUCT
const deleteProduct = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('products').doc(req.params.id);
    const doc = await ref.get();

    const product = doc.data();

    if (product.seller_id !== req.user.uid && req.user.role !== 'admin') {
      return res.status(403).json({ message: "Not allowed" });
    }

    await ref.delete();

    res.json({ message: "Deleted" });

  } catch {
    res.status(500).json({ message: "Error deleting product" });
  }
};

// 👤 GET MY PRODUCTS
const getMyProducts = async (req, res) => {
  try {
    const db = getFirestore();

    const snapshot = await db.collection('products')
      .where('seller_id', '==', req.user.uid)
      .get();

    const products = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ success: true, data: { products } });

  } catch {
    res.status(500).json({ message: "Error fetching user products" });
  }
};

module.exports = {
  addProduct,
  getProducts,
  getProductById,
  markSold,
  deleteProduct,
  getMyProducts
};