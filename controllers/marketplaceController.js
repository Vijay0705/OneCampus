const path = require('path');
const { getFirestore, getStorageBucket } = require('../config/firebase');

const allowedStatuses = ['active', 'sold'];

const toNumber = (value) => {
  if (value === null || value === undefined) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const buildPublicImageUrl = (bucketName, filePath) => {
  return `https://storage.googleapis.com/${bucketName}/${filePath}`;
};

const extractFilePathFromPublicUrl = (url, bucketName) => {
  const prefix = `https://storage.googleapis.com/${bucketName}/`;
  if (!url || !url.startsWith(prefix)) return null;
  return url.slice(prefix.length);
};

const uploadMarketplaceImage = async (file) => {
  if (!file) return null;

  const bucket = getStorageBucket();
  const extension = path.extname(file.originalname || '').toLowerCase() || '.jpg';
  const fileName = `marketplace/${Date.now()}_${Math.random()
    .toString(36)
    .slice(2)}${extension}`;

  const uploadedFile = bucket.file(fileName);

  await uploadedFile.save(file.buffer, {
    metadata: {
      contentType: file.mimetype || 'image/jpeg',
      cacheControl: 'public,max-age=3600',
    },
  });

  return buildPublicImageUrl(bucket.name, fileName);
};

const deleteMarketplaceImageIfOwned = async (imageUrl) => {
  if (!imageUrl) return;

  try {
    const bucket = getStorageBucket();
    const filePath = extractFilePathFromPublicUrl(imageUrl, bucket.name);
    if (!filePath) return;

    await bucket.file(filePath).delete({ ignoreNotFound: true });
  } catch (error) {
    console.error('deleteMarketplaceImageIfOwned error:', error.message);
  }
};

const assertOwnerOrAdmin = (product, user) => {
  const ownerId = product.sellerId || product.seller_id;
  return ownerId === user.uid || user.role === 'admin';
};

const addProduct = async (req, res) => {
  try {
    const db = getFirestore();
    const { title, description, price, category, condition, contact } = req.body;

    const parsedPrice = toNumber(price);
    if (!title || parsedPrice === null) {
      return res.status(400).json({
        success: false,
        message: 'Title and valid price are required',
      });
    }

    const imageUrl = await uploadMarketplaceImage(req.file);

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

    return res.status(201).json({
      success: true,
      message: 'Product added',
      data: product,
    });
  } catch (error) {
    console.error('addProduct error:', error);
    return res.status(500).json({ success: false, message: 'Error adding product' });
  }
};

const getProducts = async (req, res) => {
  try {
    const db = getFirestore();

    let query = db.collection('products');
    const { category, status } = req.query;

    const reqStatus = status || 'active';
    if (allowedStatuses.includes(reqStatus)) {
      query = query.where('status', '==', reqStatus);
    }

    if (category && category !== 'All') {
      query = query.where('category', '==', category);
    }

    const snapshot = await query.get();

    const products = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));

    return res.json({ success: true, data: products });
  } catch (error) {
    console.error('getProducts error:', error);
    return res.status(500).json({ success: false, message: 'Error fetching products' });
  }
};

const getProductById = async (req, res) => {
  try {
    const db = getFirestore();
    const doc = await db.collection('products').doc(req.params.id).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    return res.json({ success: true, data: { id: doc.id, ...doc.data() } });
  } catch (error) {
    console.error('getProductById error:', error);
    return res.status(500).json({ success: false, message: 'Error fetching product' });
  }
};

const updateProduct = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('products').doc(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    const product = doc.data();

    if (!assertOwnerOrAdmin(product, req.user)) {
      return res.status(403).json({ success: false, message: 'Not allowed' });
    }

    const updateData = { updatedAt: new Date().toISOString() };

    if (req.body.title !== undefined) updateData.title = String(req.body.title).trim();
    if (req.body.description !== undefined) updateData.description = String(req.body.description).trim();
    if (req.body.category !== undefined) updateData.category = req.body.category;
    if (req.body.condition !== undefined) updateData.condition = req.body.condition;
    if (req.body.contact !== undefined) updateData.contact = req.body.contact;
    if (req.body.status !== undefined && allowedStatuses.includes(req.body.status)) {
      updateData.status = req.body.status;
    }

    if (req.body.price !== undefined) {
      const parsedPrice = toNumber(req.body.price);
      if (parsedPrice === null) {
        return res.status(400).json({ success: false, message: 'Invalid price' });
      }
      updateData.price = parsedPrice;
    }

    if (req.file) {
      const imageUrl = await uploadMarketplaceImage(req.file);
      updateData.imageUrl = imageUrl;
      await deleteMarketplaceImageIfOwned(product.imageUrl || product.image_url || product.image);
    }

    await ref.update(updateData);

    return res.json({
      success: true,
      message: 'Product updated',
      data: { ...product, ...updateData, id: req.params.id },
    });
  } catch (error) {
    console.error('updateProduct error:', error);
    return res.status(500).json({ success: false, message: 'Error updating product' });
  }
};

const updateProductStatus = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('products').doc(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    if (!assertOwnerOrAdmin(doc.data(), req.user)) {
      return res.status(403).json({ success: false, message: 'Not allowed' });
    }

    const status = String(req.body.status || '').toLowerCase();
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    await ref.update({ status, updatedAt: new Date().toISOString() });

    return res.json({ success: true, message: `Status updated to ${status}` });
  } catch (error) {
    console.error('updateProductStatus error:', error);
    return res.status(500).json({ success: false, message: 'Error updating status' });
  }
};

const markSold = async (req, res) => {
  req.body.status = 'sold';
  return updateProductStatus(req, res);
};

const deleteProduct = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('products').doc(req.params.id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    const product = doc.data();

    if (!assertOwnerOrAdmin(product, req.user)) {
      return res.status(403).json({ success: false, message: 'Not allowed' });
    }

    await ref.delete();
    await deleteMarketplaceImageIfOwned(product.imageUrl || product.image_url || product.image);

    return res.json({ success: true, message: 'Deleted' });
  } catch (error) {
    console.error('deleteProduct error:', error);
    return res.status(500).json({ success: false, message: 'Error deleting product' });
  }
};

const getMyProducts = async (req, res) => {
  try {
    const db = getFirestore();

    const snapshot = await db
      .collection('products')
      .where('sellerId', '==', req.user.uid)
      .get();

    let products = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    // Sort by creation date descending
    products.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));

    return res.json({ success: true, data: products });
  } catch (error) {
    console.error('getMyProducts error:', error);
    return res.status(500).json({ success: false, message: 'Error fetching user products' });
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
