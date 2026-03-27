// middleware/errorHandler.js

// 404 Not Found middleware
const notFound = (req, res, next) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.originalUrl}`,
  });
};

// Global Error Handler middleware
const errorHandler = (err, req, res, next) => {
  console.error("🔥 Error:", err);

  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;

  res.status(statusCode).json({
    success: false,
    message: err.message || "Internal Server Error",
  });
};

module.exports = {
  notFound,
  errorHandler,
};