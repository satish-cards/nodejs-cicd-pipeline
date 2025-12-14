const express = require('express');
const config = require('./config');
const { log, requestLogger } = require('./middleware/logger');
const { metricsMiddleware } = require('./middleware/metrics');
const errorHandler = require('./middleware/errorHandler');
const healthRouter = require('./routes/health');
const usersRouter = require('./routes/users');
const dataRouter = require('./routes/data');
const metricsRouter = require('./routes/metrics');

const app = express();

// Middleware
app.use(express.json());
app.use(metricsMiddleware);
app.use(requestLogger);

// Routes
app.use('/health', healthRouter);
app.use('/api/users', usersRouter);
app.use('/api/data', dataRouter);
app.use('/metrics', metricsRouter);

// 404 handler
app.use((req, res, next) => {
  const error = new Error('Not Found');
  error.status = 404;
  error.code = 'Page Not Found';
  next(error);
});

// Error handler (must be last)
app.use(errorHandler);

// Only start server if not in test mode
if (require.main === module) {
  // Start server
  const server = app.listen(config.server.port, config.server.host, () => {
    log('info', `Server started successfully on port ${config.server.port}`, {
      port: config.server.port,
      environment: config.server.environment
    });
  });

  // Graceful shutdown
  process.on('SIGTERM', () => {
    log('info', 'SIGTERM received, shutting down gracefully');
    server.close(() => {
      log('info', 'Server closed');
      process.exit(0);
    });
  });

  process.on('SIGINT', () => {
    log('info', 'SIGINT received, shutting down gracefully');
    server.close(() => {
      log('info', 'Server closed');
      process.exit(0);
    });
  });
}

module.exports = app;
