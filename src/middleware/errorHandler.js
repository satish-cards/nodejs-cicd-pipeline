const { log } = require('./logger');
const config = require('../config');

function errorHandler(err, req, res, _next) {
  log('error', err.message, {
    stack: err.stack,
    path: req.path,
    method: req.method
  });
  
  const statusCode = err.status || err.statusCode || 500;
  const errorResponse = {
    error: {
      message: err.message || 'Internal Server Error',
      code: err.code || 'INTERNAL_ERROR',
      timestamp: new Date().toISOString()
    }
  };
  
  // Include stack trace and additional details only if enabled
  if (config.features.enableDetailedErrors) {
    errorResponse.error.details = {
      stack: err.stack,
      path: req.path,
      method: req.method
    };
  }
  
  res.status(statusCode).json(errorResponse);
}

module.exports = errorHandler;
