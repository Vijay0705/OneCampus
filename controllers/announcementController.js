const { getFirestore } = require('../config/firebase');
const {
  sendAnnouncementNotificationToStudents,
} = require('../services/notificationService');

const ALLOWED_PRIORITIES = ['low', 'medium', 'high'];

const normalizePriority = (priority) => {
  const value = String(priority || 'low').toLowerCase();
  return ALLOWED_PRIORITIES.includes(value) ? value : 'low';
};

const buildAnnouncementPayload = (reqBody, reqUser, existing = {}) => {
  const title = String(reqBody.title || existing.title || '').trim();
  const description = String(reqBody.description || existing.description || '').trim();

  return {
    title,
    description,
    priority: normalizePriority(reqBody.priority || existing.priority || 'low'),
    department: String(reqBody.department || existing.department || 'ALL').toUpperCase(),
    isPinned:
      reqBody.isPinned === undefined
        ? Boolean(existing.isPinned || false)
        : Boolean(reqBody.isPinned),
    createdBy: existing.createdBy || reqUser.uid,
    createdByName: existing.createdByName || reqUser.name || 'Staff',
  };
};

const createAnnouncement = async (req, res) => {
  try {
    const db = getFirestore();

    const payload = buildAnnouncementPayload(req.body, req.user);

    if (!payload.title || !payload.description) {
      return res.status(400).json({
        success: false,
        message: 'Title and description are required',
      });
    }

    const announcementRef = db.collection('announcements').doc();
    const now = new Date().toISOString();

    const announcement = {
      id: announcementRef.id,
      ...payload,
      createdAt: now,
      updatedAt: now,
    };

    await announcementRef.set(announcement);

    try {
      await sendAnnouncementNotificationToStudents({
        announcementId: announcementRef.id,
        title: payload.title,
        description: payload.description,
      });
    } catch (error) {
      console.error('Announcement notification error:', error);
    }

    return res.status(201).json({
      success: true,
      message: 'Announcement created',
      data: announcement,
    });
  } catch (err) {
    console.error('createAnnouncement error:', err);
    return res.status(500).json({ success: false, message: 'Failed to create announcement' });
  }
};

const getAnnouncements = async (req, res) => {
  try {
    const db = getFirestore();

    let query = db.collection('announcements').orderBy('createdAt', 'desc');

    const snapshot = await query.get();
    let announcements = snapshot.docs.map((doc) => {
      const data = doc.data();
      return { id: doc.id, ...data };
    });

    if (req.user?.role === 'student' && req.user?.dept) {
      const dept = String(req.user.dept).toUpperCase();
      announcements = announcements.filter(
        (item) => item.department === 'ALL' || item.department === dept
      );
    }

    return res.json({ success: true, data: announcements });
  } catch (err) {
    console.error('getAnnouncements error:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch announcements' });
  }
};

const updateAnnouncement = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('announcements').doc(req.params.id);
    const snapshot = await ref.get();

    if (!snapshot.exists) {
      return res.status(404).json({ success: false, message: 'Announcement not found' });
    }

    const existing = snapshot.data();
    const payload = buildAnnouncementPayload(req.body, req.user, existing);

    if (!payload.title || !payload.description) {
      return res.status(400).json({
        success: false,
        message: 'Title and description are required',
      });
    }

    const updateData = {
      ...payload,
      updatedAt: new Date().toISOString(),
    };

    await ref.update(updateData);

    return res.json({
      success: true,
      message: 'Announcement updated',
      data: { id: req.params.id, ...existing, ...updateData },
    });
  } catch (err) {
    console.error('updateAnnouncement error:', err);
    return res.status(500).json({ success: false, message: 'Failed to update announcement' });
  }
};

const deleteAnnouncement = async (req, res) => {
  try {
    const db = getFirestore();
    const ref = db.collection('announcements').doc(req.params.id);
    const snapshot = await ref.get();

    if (!snapshot.exists) {
      return res.status(404).json({ success: false, message: 'Announcement not found' });
    }

    await ref.delete();

    return res.json({ success: true, message: 'Announcement deleted' });
  } catch (err) {
    console.error('deleteAnnouncement error:', err);
    return res.status(500).json({ success: false, message: 'Failed to delete announcement' });
  }
};

module.exports = {
  createAnnouncement,
  getAnnouncements,
  updateAnnouncement,
  deleteAnnouncement,
};