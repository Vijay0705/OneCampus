const { getFirestore } = require('../config/firebase');
const { uploadToR2, deleteFromR2 } = require('../services/r2Upload');

const allowedStatuses = ['active', 'sold'];

const toNumber = (value) => {
  if (value === null || value === undefined) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

/* ================= ADD PRODUCT ================= */
const addProduct = async (req, res) => {
  try {
    const db = getFirestore();
    const { title, description, price, category, condition, contact } =
      req.body;

    const parsedPrice = toNumber(price);
    if (!title || parsedPrice === null) {
      return res.status(400).json({
        success: false,
        message: 'Title and valid price are required',
      });
    }

    let imageUrl = null;

    // 🔥 DEBUG
    console.log("FILE RECEIVED:", req.file);

    // ✅ ONLY R2 UPLOAD
    if (req.file) {
      try {
        imageUrl = await uploadToR2(req.file, 'marketplace');
      } catch (err) {
        console.error("R2 UPLOAD ERROR:", err);
        throw err; // 🔥 show real error
      }
    }

    const ref = db.collection('products').doc();
    const now = new Date().toISOString();

    const product = {
      id: ref.id,
      title: String(title).trim(),
      description: String(description || '').trim(),
      price: parsedPrice,
      category: category || 'Other',
      condition: condition || 'used',
      imageUrl,
      contact: contact || '',
      sellerId: req.user.uid,
      sellerName: req.user.name || 'Student',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    };

    await ref.set(product);

    res.status(201).json({
      success: true,
      message: 'Product added successfully',
      data: product,
    });

  } catch (error) {
    console.error('addProduct error:', error);

    res.status(500).json({
      success: false,
      message: error.message, // 🔥 real error
    });
  }
};

/* ================= GET ALL PRODUCTS ================= */
const getProducts = async (req, res) => {
  try {
    const { category, minPrice, maxPrice, status } = req.query;
    const db = getFirestore();
    
    let query = db.collection('products');
    
    if (category && category !== 'All') {
      query = query.where('category', '==', category);
    }
    
    if (status) {
      query = query.where('status', '==', status);
    }
    
    const snapshot = await query.get();
    let products = snapshot.docs.map(doc => doc.data());
    
    if (minPrice || maxPrice) {
      products = products.filter(p => {
        let price = Number(p.price) || 0;
        if (minPrice && price < Number(minPrice)) return false;
        if (maxPrice && price > Number(maxPrice)) return false;
        return true;
      });
    }

    res.json({ success: true, data: products });
  } catch (error) {
    console.error('getProducts error:', error);
    res.status(500).json({ success: false, message: 'Error fetching products' });
  }
};

/* ================= GET PRODUCT BY ID ================= */
const getProductById = async (req, res) => {
  try {
    const db = getFirestore();
    const doc = await db.collection('products').doc(req.params.id).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    res.json({ success: true, data: doc.data() });
  } catch (error) {
    console.error('getProductById error:', error);
    res.status(500).json({ success: false, message: 'Error fetching product' });
  }
};

/* ================= GET MY PRODUCTS ================= */
const getMyProducts = async (req, res) => {
  try {
    const db = getFirestore();
    const snapshot = await db
      .collection('products')
      .where('sellerId', '==', req.user.uid)
      .get();

    const products = snapshot.docs.map(doc => doc.data());

    res.json({ success: true, data: products });
  } catch (error) {
    console.error('getMyProducts error:', error);
    res.status(500).json({ success: false, message: 'Error fetching my products' });
  }
};

/* ================= UPDATE PRODUCT ================= */
const updateProduct = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('products').doc(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    const product = doc.data();
    const updateData = { updatedAt: new Date().toISOString() };

    if (req.body.title !== undefined)
      updateData.title = String(req.body.title).trim();

    if (req.body.description !== undefined)
      updateData.description = String(req.body.description).trim();

    if (req.body.category !== undefined)
      updateData.category = req.body.category;

    if (req.body.condition !== undefined)
      updateData.condition = req.body.condition;

    if (req.body.contact !== undefined)
      updateData.contact = req.body.contact;

    if (
      req.body.status !== undefined &&
      allowedStatuses.includes(req.body.status)
    ) {
      updateData.status = req.body.status;
    }

    if (req.body.price !== undefined) {
      const parsedPrice = toNumber(req.body.price);
      if (parsedPrice === null) {
        return res.status(400).json({ success: false, message: 'Invalid price' });
      }
      updateData.price = parsedPrice;
    }

    // ✅ ONLY R2 UPDATE
    if (req.file) {
      try {
        const imageUrl = await uploadToR2(req.file, 'marketplace');
        updateData.imageUrl = imageUrl;

        if (product.imageUrl) {
          await deleteFromR2(product.imageUrl);
        }

      } catch (err) {
        console.error("R2 UPDATE ERROR:", err);
        throw err;
      }
    }

    await ref.update(updateData);

    res.json({
      success: true,
      message: 'Product updated',
      data: { ...product, ...updateData },
    });

  } catch (error) {
    console.error('updateProduct error:', error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/* ================= MARK SOLD ================= */
const markSold = async (req, res) => {
  try {
    const db = getFirestore();
    await db.collection('products').doc(req.params.id).update({
      status: 'sold',
      updatedAt: new Date().toISOString(),
    });

    res.json({ success: true, message: 'Marked as sold' });
  } catch (error) {
    console.error('markSold error:', error);
    res.status(500).json({ success: false, message: 'Error updating status' });
  }
};

/* ================= UPDATE STATUS ================= */
const updateProductStatus = async (req, res) => {
  try {
    const { status } = req.body;

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const db = getFirestore();
    await db.collection('products').doc(req.params.id).update({
      status,
      updatedAt: new Date().toISOString(),
    });

    res.json({ success: true, message: 'Status updated' });
  } catch (error) {
    console.error('updateProductStatus error:', error);
    res.status(500).json({ success: false, message: 'Error updating status' });
  }
};

/* ================= DELETE PRODUCT ================= */
const deleteProduct = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('products').doc(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    const product = doc.data();

    await ref.delete();

    if (product.imageUrl) {
      await deleteFromR2(product.imageUrl);
    }

    res.json({ success: true, message: 'Deleted' });

  } catch (error) {
    console.error('deleteProduct error:', error);
    res.status(500).json({ success: false, message: 'Error deleting product' });
  }
};

module.exports = {
  addProduct,
  getProducts,
  getProductById,
  updateProduct,
  updateProductStatus,
  markSold,
  deleteProduct,
  getMyProducts,
};
