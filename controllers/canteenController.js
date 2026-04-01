const { getFirestore } = require('../config/firebase');

const MAX_ORDERS_PER_SLOT = 50;

// ➕ ADD ITEM (ADMIN)
const addItem = async (req, res) => {
  try {
    const db = getFirestore();
    const { name, price, quantity, description, category } = req.body;

    const today = new Date().toISOString().split('T')[0];
    const ref = db.collection('canteen_items').doc();

    const newItem = {
      id: ref.id,
      name,
      description: description || '',
      price: Number(price),
      quantity: Number(quantity),
      available_quantity: Number(quantity),
      is_available: true,
      category: category || 'General',
      date: today,
      createdAt: new Date().toISOString()
    };

    await ref.set(newItem);

    res.json({ success: true, message: "Item added", data: newItem });

  } catch (error) {
    console.error('addItem error:', error);
    res.status(500).json({ success: false, message: "Error adding item" });
  }
};

// 📋 GET TODAY MENU
const getTodayItems = async (req, res) => {
  try {
    const db = getFirestore();
    const today = new Date().toISOString().split('T')[0];

    const snapshot = await db.collection('canteen_items')
      .where('date', '==', today)
      .where('is_available', '==', true)
      .get();

    const items = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ success: true, data: { items } });

  } catch (error) {
    console.error('getTodayItems error:', error);
    res.status(500).json({ success: false, message: "Error fetching menu" });
  }
};

// 🛒 PLACE ORDER (TRANSACTION SAFE)
const placeOrder = async (req, res) => {
  try {
    const db = getFirestore();
    const { items, timeSlot = 'now' } = req.body;

    const today = new Date().toISOString().split('T')[0];

    const result = await db.runTransaction(async (t) => {
      const slotSnap = await db.collection('orders')
        .where('timeSlot', '==', timeSlot)
        .where('date', '==', today)
        .get();

      if (slotSnap.size >= MAX_ORDERS_PER_SLOT) {
        throw new Error("Time slot full");
      }

      let total = 0;
      const enrichedItems = [];

      for (let item of items) {
        const ref = db.collection('canteen_items').doc(item.item_id);
        const doc = await t.get(ref);

        if (!doc.exists) throw new Error(`Item ${item.item_id} not found`);

        const data = doc.data();

        if (!data.is_available || data.available_quantity < item.quantity) {
          throw new Error(`${data.name} is out of stock`);
        }

        t.update(ref, {
          available_quantity: data.available_quantity - item.quantity,
          is_available: data.available_quantity - item.quantity > 0
        });

        const subtotal = data.price * item.quantity;
        total += subtotal;
        enrichedItems.push({
          ...item,
          name: data.name,
          price: data.price,
          subtotal
        });
      }

      const orderRef = db.collection('orders').doc();

      const order = {
        id: orderRef.id,
        userId: req.user.uid,
        studentName: req.user.name || "Student",
        items: enrichedItems,
        total,
        status: "pending",
        timeSlot,
        date: today,
        createdAt: new Date().toISOString()
      };

      t.set(orderRef, order);

      return order;
    });

    res.json({ success: true, data: result });

  } catch (e) {
    console.error('placeOrder error:', e);
    res.status(400).json({ success: false, message: e.message });
  }
};

// 📦 GET ORDERS
const getOrders = async (req, res) => {
  try {
    const db = getFirestore();
    const today = new Date().toISOString().split('T')[0];

    let query = db.collection('orders').where('date', '==', today);

    if (req.user.role === 'student') {
      query = query.where('userId', '==', req.user.uid);
    }

    const snapshot = await query.get();

    const orders = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    })).sort((a,b) => (a.createdAt < b.createdAt ? 1 : -1));

    res.json({ success: true, data: { orders } });

  } catch (error) {
    console.error('getOrders error:', error);
    res.status(500).json({ success: false, message: "Error fetching orders" });
  }
};

// 🔄 UPDATE ORDER STATUS
const updateOrderStatus = async (req, res) => {
  try {
    const allowedStatuses = ["pending", "preparing", "ready", "completed", "cancelled"];
    const flow = ["pending", "preparing", "ready", "completed"];

    const db = getFirestore();
    const ref = db.collection('orders').doc(req.params.id);
    const snapshot = await ref.get();

    if (!snapshot.exists) {
      return res.status(404).json({ success: false, message: "Order not found" });
    }

    const order = snapshot.data();
    const current = order.status;
    const next = req.body.status;

    if (!allowedStatuses.includes(next)) {
      return res.status(400).json({ success: false, message: "Invalid status" });
    }

    // Optional flow check for admin convenience, but allow explicit jumps if needed?
    // User wants to mark as preparing -> ready -> completed.
    // If it's a student marking as completed, verify it's ready.
    if (req.user.role === 'student' && next === 'completed') {
       if (current !== 'ready') {
         return res.status(400).json({ success: false, message: "Order must be ready before completion" });
       }
    }

    await ref.update({ status: next, updatedAt: new Date().toISOString() });

    res.json({ success: true, message: "Order status updated", data: { id: req.params.id, status: next } });
  } catch (error) {
    console.error('updateOrderStatus error:', error);
    res.status(500).json({ success: false, message: "Error updating order status" });
  }
};

// ❌ REMOVE ITEM (ADMIN)
const removeItem = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('canteen_items').doc(req.params.id);

    await ref.update({
      is_available: false,
      updatedAt: new Date().toISOString()
    });

    res.json({ success: true, message: "Item removed" });

  } catch (error) {
    console.error('removeItem error:', error);
    res.status(500).json({ success: false, message: "Error removing item" });
  }
};

module.exports = {
  addItem,
  getTodayItems,
  placeOrder,
  getOrders,
  updateOrderStatus,
  removeItem
};