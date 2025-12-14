const express = require('express');
const config = require('../config');

const router = express.Router();

const startTime = Date.now();

router.get('/', (req, res) => {
  const uptime = Math.floor((Date.now() - startTime) / 1000);
  
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: config.app.version,
    uptime,
    environment: config.server.environment
  });
});

module.exports = router;
