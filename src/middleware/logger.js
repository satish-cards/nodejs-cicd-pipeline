const config = require('../config');

function formatLog(data) {
  if (config.logging.format === 'json') {
    return JSON.stringify(data);
  }
  return `[${data.timestamp}] ${data.level.toUpperCase()} - ${data.message}${data.method ? ` ${data.method} ${data.path} ${data.statusCode} ${data.duration}ms` : ''}`;
}

function log(level, message, metadata = {}) {
  const logData = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...metadata
  };
  
  console.log(formatLog(logData));
}

function requestLogger(req, res, next) {
  const startTime = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    log('info', 'Request processed', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration
    });
  });
  
  next();
}

module.exports = {
  log,
  requestLogger
};
