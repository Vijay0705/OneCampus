const { getFirestore } = require('../config/firebase');

const MAX_ORDERS_PER_SLOT = 50;

// ➕ ADD ITEM (ADMIN)
const addItem = async (req, res) => {
  try {
    const db = getFirestore();
    const { name, price, quantity } = req.body;

    const today = new Date().toISOString().split('T')[0];

    const ref = db.collection('canteen_items').doc();

    await ref.set({
      id: ref.id,
      name,
      price,
      quantity,
      available_quantity: quantity,
      is_available: true,
      date: today,
      createdAt: new Date().toISOString()
    });

    res.json({ message: "Item added" });

  } catch {
    res.status(500).json({ message: "Error adding item" });
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

  } catch {
    res.status(500).json({ message: "Error fetching menu" });
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

      for (let item of items) {
        const ref = db.collection('canteen_items').doc(item.item_id);
        const doc = await t.get(ref);

        if (!doc.exists) throw new Error("Item not found");

        const data = doc.data();

        if (!data.is_available || data.available_quantity < item.quantity) {
          throw new Error("Out of stock");
        }

        t.update(ref, {
          available_quantity: data.available_quantity - item.quantity,
          is_available: data.available_quantity - item.quantity > 0
        });

        total += data.price * item.quantity;
      }

      const orderRef = db.collection('orders').doc();

      const order = {
        id: orderRef.id,
        userId: req.user.uid,
        studentName: req.user.name || "Student",
        items,
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
    res.status(400).json({ message: e.message });
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
    }));

    res.json({ success: true, data: { orders } });

  } catch {
    res.status(500).json({ message: "Error fetching orders" });
  }
};

// 🔄 UPDATE ORDER STATUS
const updateOrderStatus = async (req, res) => {
  const flow = ["pending", "preparing", "ready", "completed"];

  const db = getFirestore();
  const ref = db.collection('orders').doc(req.params.id);
  const doc = await ref.get();

  const current = doc.data().status;
  const next = req.body.status;

  if (flow.indexOf(next) !== flow.indexOf(current) + 1) {
    return res.status(400).json({ message: "Invalid status flow" });
  }

  await ref.update({ status: next });

  res.json({ message: "Updated" });
};

// ❌ REMOVE ITEM (ADMIN)
const removeItem = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('canteen_items').doc(req.params.id);

    await ref.update({
      is_available: false
    });

    res.json({ message: "Item removed" });

  } catch {
    res.status(500).json({ message: "Error removing item" });
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