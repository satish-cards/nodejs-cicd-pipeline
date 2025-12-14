const config = require('../config');

// Metrics storage
const metrics = {
  requestCount: {},
  responseTimes: {},
  errorCount: {},
  totalRequests: 0,
  totalErrors: 0
};

// Helper to get or initialize endpoint metrics
function getEndpointMetrics(endpoint) {
  if (!metrics.requestCount[endpoint]) {
    metrics.requestCount[endpoint] = 0;
    metrics.responseTimes[endpoint] = [];
    metrics.errorCount[endpoint] = 0;
  }
}

// Record a request
function recordRequest(endpoint, duration, statusCode) {
  getEndpointMetrics(endpoint);
  
  metrics.requestCount[endpoint]++;
  metrics.totalRequests++;
  
  // Store response time
  metrics.responseTimes[endpoint].push(duration);
  
  // Keep only last 1000 response times per endpoint to prevent memory issues
  if (metrics.responseTimes[endpoint].length > 1000) {
    metrics.responseTimes[endpoint].shift();
  }
  
  // Record errors (4xx and 5xx)
  if (statusCode >= 400) {
    metrics.errorCount[endpoint]++;
    metrics.totalErrors++;
  }
}

// Calculate percentile
function calculatePercentile(values, percentile) {
  if (values.length === 0) return 0;
  
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.ceil((percentile / 100) * sorted.length) - 1;
  return sorted[Math.max(0, index)];
}

// Get metrics summary
function getMetrics() {
  const summary = {
    total_requests: metrics.totalRequests,
    total_errors: metrics.totalErrors,
    endpoints: {}
  };
  
  for (const endpoint in metrics.requestCount) {
    const responseTimes = metrics.responseTimes[endpoint];
    const avgResponseTime = responseTimes.length > 0
      ? responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length
      : 0;
    
    summary.endpoints[endpoint] = {
      request_count: metrics.requestCount[endpoint],
      error_count: metrics.errorCount[endpoint],
      error_rate: metrics.requestCount[endpoint] > 0
        ? (metrics.errorCount[endpoint] / metrics.requestCount[endpoint]) * 100
        : 0,
      avg_response_time_ms: Math.round(avgResponseTime * 100) / 100,
      p50_response_time_ms: calculatePercentile(responseTimes, 50),
      p95_response_time_ms: calculatePercentile(responseTimes, 95),
      p99_response_time_ms: calculatePercentile(responseTimes, 99)
    };
  }
  
  return summary;
}

// Format metrics in Prometheus format
function formatPrometheusMetrics() {
  const summary = getMetrics();
  let output = '';
  
  // Total requests
  output += '# HELP http_requests_total Total number of HTTP requests\n';
  output += '# TYPE http_requests_total counter\n';
  output += `http_requests_total ${summary.total_requests}\n\n`;
  
  // Total errors
  output += '# HELP http_errors_total Total number of HTTP errors (4xx and 5xx)\n';
  output += '# TYPE http_errors_total counter\n';
  output += `http_errors_total ${summary.total_errors}\n\n`;
  
  // Per-endpoint metrics
  output += '# HELP http_requests_by_endpoint Total requests per endpoint\n';
  output += '# TYPE http_requests_by_endpoint counter\n';
  for (const endpoint in summary.endpoints) {
    output += `http_requests_by_endpoint{endpoint="${endpoint}"} ${summary.endpoints[endpoint].request_count}\n`;
  }
  output += '\n';
  
  // Error count by endpoint
  output += '# HELP http_errors_by_endpoint Total errors per endpoint\n';
  output += '# TYPE http_errors_by_endpoint counter\n';
  for (const endpoint in summary.endpoints) {
    output += `http_errors_by_endpoint{endpoint="${endpoint}"} ${summary.endpoints[endpoint].error_count}\n`;
  }
  output += '\n';
  
  // Error rate by endpoint
  output += '# HELP http_error_rate_by_endpoint Error rate per endpoint (percentage)\n';
  output += '# TYPE http_error_rate_by_endpoint gauge\n';
  for (const endpoint in summary.endpoints) {
    output += `http_error_rate_by_endpoint{endpoint="${endpoint}"} ${summary.endpoints[endpoint].error_rate.toFixed(2)}\n`;
  }
  output += '\n';
  
  // Average response time
  output += '# HELP http_response_time_avg_ms Average response time in milliseconds\n';
  output += '# TYPE http_response_time_avg_ms gauge\n';
  for (const endpoint in summary.endpoints) {
    output += `http_response_time_avg_ms{endpoint="${endpoint}"} ${summary.endpoints[endpoint].avg_response_time_ms}\n`;
  }
  output += '\n';
  
  // P50 response time
  output += '# HELP http_response_time_p50_ms P50 response time in milliseconds\n';
  output += '# TYPE http_response_time_p50_ms gauge\n';
  for (const endpoint in summary.endpoints) {
    output += `http_response_time_p50_ms{endpoint="${endpoint}"} ${summary.endpoints[endpoint].p50_response_time_ms}\n`;
  }
  output += '\n';
  
  // P95 response time
  output += '# HELP http_response_time_p95_ms P95 response time in milliseconds\n';
  output += '# TYPE http_response_time_p95_ms gauge\n';
  for (const endpoint in summary.endpoints) {
    output += `http_response_time_p95_ms{endpoint="${endpoint}"} ${summary.endpoints[endpoint].p95_response_time_ms}\n`;
  }
  output += '\n';
  
  // P99 response time
  output += '# HELP http_response_time_p99_ms P99 response time in milliseconds\n';
  output += '# TYPE http_response_time_p99_ms gauge\n';
  for (const endpoint in summary.endpoints) {
    output += `http_response_time_p99_ms{endpoint="${endpoint}"} ${summary.endpoints[endpoint].p99_response_time_ms}\n`;
  }
  
  return output;
}

// Middleware to track metrics
function metricsMiddleware(req, res, next) {
  if (!config.features.enableMetrics) {
    return next();
  }
  
  const startTime = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const endpoint = req.route ? req.route.path : req.path;
    recordRequest(endpoint, duration, res.statusCode);
  });
  
  next();
}

// Reset metrics (useful for testing)
function resetMetrics() {
  metrics.requestCount = {};
  metrics.responseTimes = {};
  metrics.errorCount = {};
  metrics.totalRequests = 0;
  metrics.totalErrors = 0;
}

module.exports = {
  metricsMiddleware,
  getMetrics,
  formatPrometheusMetrics,
  recordRequest,
  resetMetrics
};
