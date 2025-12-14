const express = require('express');
const { getMetrics, formatPrometheusMetrics } = require('../middleware/metrics');
const config = require('../config');

const router = express.Router();

router.get('/', (req, res) => {
  // Check if metrics are enabled
  if (!config.features.enableMetrics) {
    return res.status(404).json({
      error: {
        message: 'Metrics endpoint is disabled',
        code: 'METRICS_DISABLED',
        timestamp: new Date().toISOString()
      }
    });
  }
  
  // Check Accept header to determine format
  const acceptHeader = req.get('Accept') || '';
  
  if (acceptHeader.includes('application/json')) {
    // Return JSON format
    res.json(getMetrics());
  } else {
    // Return Prometheus format (default)
    res.set('Content-Type', 'text/plain; version=0.0.4');
    res.send(formatPrometheusMetrics());
  }
});

module.exports = router;
