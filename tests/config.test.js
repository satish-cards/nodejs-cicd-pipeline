const config = require('../src/config');

describe('Configuration', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('should load default configuration', () => {
    const config = require('../src/config');
    expect(config.server.port).toBe(3000);
    expect(config.server.environment).toBe('test'); // Jest sets NODE_ENV to 'test'
    expect(config.logging.level).toBe('info');
  });

  it('should load PORT from environment variable', () => {
    process.env.PORT = '8080';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.server.port).toBe(8080);
  });

  it('should load NODE_ENV from environment variable', () => {
    process.env.NODE_ENV = 'production';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.server.environment).toBe('production');
  });

  it('should load LOG_LEVEL from environment variable', () => {
    process.env.LOG_LEVEL = 'debug';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.logging.level).toBe('debug');
  });

  it('should use JSON log format in production', () => {
    process.env.NODE_ENV = 'production';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.logging.format).toBe('json');
  });

  it('should use text log format in development', () => {
    process.env.NODE_ENV = 'development';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.logging.format).toBe('text');
  });

  it('should use text log format in staging', () => {
    process.env.NODE_ENV = 'staging';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.logging.format).toBe('text');
  });

  it('should load ENABLE_METRICS from environment variable', () => {
    process.env.ENABLE_METRICS = 'true';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.features.enableMetrics).toBe(true);
  });

  it('should load ENABLE_DETAILED_ERRORS from environment variable', () => {
    process.env.ENABLE_DETAILED_ERRORS = 'false';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.features.enableDetailedErrors).toBe(false);
  });

  it('should have default feature flags', () => {
    const config = require('../src/config');
    expect(config.features.enableMetrics).toBe(true);
    expect(config.features.enableDetailedErrors).toBe(true);
  });

  it('should have secrets configuration', () => {
    const config = require('../src/config');
    expect(config.secrets).toBeDefined();
    expect(config.secrets.apiKey).toBe('');
    expect(config.secrets.jwtSecret).toBe('');
    expect(config.secrets.databaseUrl).toBe('');
  });

  it('should load secrets from environment variables', () => {
    process.env.API_KEY = 'test-api-key';
    process.env.JWT_SECRET = 'test-jwt-secret';
    process.env.DATABASE_URL = 'test-db-url';
    delete require.cache[require.resolve('../src/config')];
    const config = require('../src/config');
    expect(config.secrets.apiKey).toBe('test-api-key');
    expect(config.secrets.jwtSecret).toBe('test-jwt-secret');
    expect(config.secrets.databaseUrl).toBe('test-db-url');
  });
});
