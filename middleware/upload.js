const multer = require("multer");

// Store file in memory for R2 upload
const storage = multer.memoryStorage();

// Accept all file types, large file support (up to 500MB)
const upload = multer({
  storage,
  limits: { fileSize: 500 * 1024 * 1024 }, // 500MB
});

module.exports = upload;
