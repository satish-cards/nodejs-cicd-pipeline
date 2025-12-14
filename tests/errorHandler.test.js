const request = require('supertest');
const express = require('express');
const errorHandler = require('../src/middleware/errorHandler');

describe('Error Handler', () => {
  let app;
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
    
    // Create a fresh app for each test
    app = express();
    app.use(express.json());
    
    // Test route that throws an error
    app.get('/test-error', (req, res, next) => {
      const error = new Error('Test error message');
      error.status = 400;
      error.code = 'TEST_ERROR';
      next(error);
    });
    
    app.use(errorHandler);
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('should return error with message, code, and timestamp', async () => {
    const response = await request(app).get('/test-error');
    
    expect(response.status).toBe(400);
    expect(response.body.error).toBeDefined();
    expect(response.body.error.message).toBe('Test error message');
    expect(response.body.error.code).toBe('TEST_ERROR');
    expect(response.body.error.timestamp).toBeDefined();
  });

  it('should include detailed error information when ENABLE_DETAILED_ERRORS is true', async () => {
    process.env.ENABLE_DETAILED_ERRORS = 'true';
    delete require.cache[require.resolve('../src/config')];
    delete require.cache[require.resolve('../src/middleware/errorHandler')];
    
    const errorHandler = require('../src/middleware/errorHandler');
    app = express();
    app.get('/test-error', (req, res, next) => {
      const error = new Error('Test error');
      error.status = 400;
      next(error);
    });
    app.use(errorHandler);
    
    const response = await request(app).get('/test-error');
    
    expect(response.body.error.details).toBeDefined();
    expect(response.body.error.details.stack).toBeDefined();
    expect(response.body.error.details.path).toBe('/test-error');
    expect(response.body.error.details.method).toBe('GET');
  });

  it('should not include detailed error information when ENABLE_DETAILED_ERRORS is false', async () => {
    process.env.ENABLE_DETAILED_ERRORS = 'false';
    delete require.cache[require.resolve('../src/config')];
    delete require.cache[require.resolve('../src/middleware/errorHandler')];
    
    const errorHandler = require('../src/middleware/errorHandler');
    app = express();
    app.get('/test-error', (req, res, next) => {
      const error = new Error('Test error');
      error.status = 400;
      next(error);
    });
    app.use(errorHandler);
    
    const response = await request(app).get('/test-error');
    
    expect(response.body.error.details).toBeUndefined();
  });

  it('should default to 500 status code if not specified', async () => {
    app = express();
    app.get('/test-error', (req, res, next) => {
      const error = new Error('Test error');
      next(error);
    });
    app.use(errorHandler);
    
    const response = await request(app).get('/test-error');
    expect(response.status).toBe(500);
  });

  it('should use INTERNAL_ERROR code if not specified', async () => {
    app = express();
    app.get('/test-error', (req, res, next) => {
      const error = new Error('Test error');
      next(error);
    });
    app.use(errorHandler);
    
    const response = await request(app).get('/test-error');
    expect(response.body.error.code).toBe('INTERNAL_ERROR');
  });
});
