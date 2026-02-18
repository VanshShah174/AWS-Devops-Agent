const express = require('express');
const promClient = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// State for error scenarios
let healthCheckEnabled = true;
let memoryLeakArray = [];
let requestCount = 0;

// Middleware for metrics
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.labels(req.method, req.path, res.statusCode).observe(duration);
    httpRequestTotal.labels(req.method, req.path, res.statusCode).inc();
  });
  next();
});

// Logging middleware
app.use((req, res, next) => {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  }));
  next();
});

// Routes
app.get('/', (req, res) => {
  requestCount++;
  res.json({
    service: 'DevOps Agent Demo',
    version: VERSION,
    timestamp: new Date().toISOString(),
    requestCount,
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  if (!healthCheckEnabled) {
    console.error(JSON.stringify({
      level: 'ERROR',
      message: 'Health check failed - service unhealthy',
      timestamp: new Date().toISOString()
    }));
    return res.status(503).json({ status: 'unhealthy', reason: 'Service degraded' });
  }
  
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Error scenario endpoints
app.get('/error/500', (req, res) => {
  console.error(JSON.stringify({
    level: 'ERROR',
    message: 'Intentional 500 error triggered',
    timestamp: new Date().toISOString(),
    stack: new Error().stack
  }));
  res.status(500).json({ error: 'Internal Server Error', message: 'Something went wrong!' });
});

app.get('/error/timeout', async (req, res) => {
  console.error(JSON.stringify({
    level: 'ERROR',
    message: 'Database timeout simulation started',
    timestamp: new Date().toISOString()
  }));
  
  // Simulate long database query
  setTimeout(() => {
    console.error(JSON.stringify({
      level: 'ERROR',
      message: 'Database connection timeout',
      timestamp: new Date().toISOString(),
      error: 'Connection timeout after 30000ms'
    }));
    res.status(504).json({ error: 'Gateway Timeout', message: 'Database query timed out' });
  }, 30000);
});

app.get('/error/memory-leak', (req, res) => {
  console.warn(JSON.stringify({
    level: 'WARN',
    message: 'Memory leak triggered',
    timestamp: new Date().toISOString(),
    memoryBefore: process.memoryUsage()
  }));
  
  // Intentional memory leak
  for (let i = 0; i < 100000; i++) {
    memoryLeakArray.push(new Array(1000).fill('leak'));
  }
  
  console.warn(JSON.stringify({
    level: 'WARN',
    message: 'Memory leak completed',
    timestamp: new Date().toISOString(),
    memoryAfter: process.memoryUsage(),
    leakSize: memoryLeakArray.length
  }));
  
  res.json({ 
    message: 'Memory leak triggered', 
    arraySize: memoryLeakArray.length,
    memory: process.memoryUsage()
  });
});

app.get('/error/cpu-spike', (req, res) => {
  console.warn(JSON.stringify({
    level: 'WARN',
    message: 'CPU spike triggered',
    timestamp: new Date().toISOString()
  }));
  
  const start = Date.now();
  let result = 0;
  
  // CPU intensive operation
  while (Date.now() - start < 5000) {
    result += Math.sqrt(Math.random());
  }
  
  console.warn(JSON.stringify({
    level: 'WARN',
    message: 'CPU spike completed',
    timestamp: new Date().toISOString(),
    duration: Date.now() - start
  }));
  
  res.json({ message: 'CPU spike completed', result, duration: Date.now() - start });
});

app.get('/error/disable-health', (req, res) => {
  healthCheckEnabled = false;
  console.error(JSON.stringify({
    level: 'ERROR',
    message: 'Health check disabled',
    timestamp: new Date().toISOString()
  }));
  res.json({ message: 'Health check disabled' });
});

app.get('/error/enable-health', (req, res) => {
  healthCheckEnabled = true;
  console.info(JSON.stringify({
    level: 'INFO',
    message: 'Health check enabled',
    timestamp: new Date().toISOString()
  }));
  res.json({ message: 'Health check enabled' });
});

app.get('/error/clear-memory', (req, res) => {
  const before = memoryLeakArray.length;
  memoryLeakArray = [];
  global.gc && global.gc();
  
  console.info(JSON.stringify({
    level: 'INFO',
    message: 'Memory cleared',
    timestamp: new Date().toISOString(),
    clearedItems: before
  }));
  
  res.json({ message: 'Memory cleared', clearedItems: before, memory: process.memoryUsage() });
});

// 404 handler
app.use((req, res) => {
  console.warn(JSON.stringify({
    level: 'WARN',
    message: 'Route not found',
    path: req.path,
    timestamp: new Date().toISOString()
  }));
  res.status(404).json({ error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(JSON.stringify({
    level: 'ERROR',
    message: err.message,
    stack: err.stack,
    timestamp: new Date().toISOString()
  }));
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start server
app.listen(PORT, () => {
  console.log(JSON.stringify({
    level: 'INFO',
    message: `Server started on port ${PORT}`,
    version: VERSION,
    timestamp: new Date().toISOString()
  }));
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log(JSON.stringify({
    level: 'INFO',
    message: 'SIGTERM received, shutting down gracefully',
    timestamp: new Date().toISOString()
  }));
  process.exit(0);
});
