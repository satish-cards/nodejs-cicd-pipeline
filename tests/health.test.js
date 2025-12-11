const request = require('supertest');
const express = require('express');
const healthRoute = require('../src/routes/health');

describe('Health Endpoint', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use('/health', healthRoute);
  });

  it('should return 200 status code', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
  });

  it('should return JSON content type', async () => {
    const response = await request(app).get('/health');
    expect(response.headers['content-type']).toMatch(/json/);
  });

  it('should return status ok', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('status', 'ok');
  });

  it('should return timestamp', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('timestamp');
    expect(new Date(response.body.timestamp)).toBeInstanceOf(Date);
  });

  it('should return version', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('version');
    expect(typeof response.body.version).toBe('string');
  });

  it('should return uptime', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('uptime');
    expect(typeof response.body.uptime).toBe('number');
  });

  it('should return environment', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toHaveProperty('environment');
    expect(typeof response.body.environment).toBe('string');
  });
});
