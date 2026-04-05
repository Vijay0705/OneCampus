const multer = require('multer');

// Store file in memory (REQUIRED for R2 upload)
const storage = multer.memoryStorage();

// Optional: file filter (you can restrict if needed)
const fileFilter = (req, file, cb) => {
  // Allow all files by default
  // You can restrict if needed, e.g.:
  // if (file.mimetype === 'application/pdf' || file.mimetype.startsWith('image/')) {
  //   cb(null, true);
  // } else {
  //   cb(new Error('Invalid file type'), false);
  // }

  cb(null, true);
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: fileFilter,
});

module.exports = upload;
