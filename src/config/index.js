require('dotenv').config();

const config = {
  server: {
    port: parseInt(process.env.PORT, 10) || 3000,
    host: process.env.HOST || '0.0.0.0',
    environment: process.env.NODE_ENV || 'development'
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: process.env.NODE_ENV === 'production' ? 'json' : 'text'
  },
  app: {
    version: process.env.APP_VERSION || process.env.npm_package_version || '1.0.0'
  },
  features: {
    enableMetrics: process.env.ENABLE_METRICS === 'true',
    enableDetailedErrors: process.env.ENABLE_DETAILED_ERRORS !== 'false'
  },
  secrets: {
    apiKey: process.env.API_KEY || '',
    jwtSecret: process.env.JWT_SECRET || '',
    databaseUrl: process.env.DATABASE_URL || ''
  }
};

module.exports = config;
