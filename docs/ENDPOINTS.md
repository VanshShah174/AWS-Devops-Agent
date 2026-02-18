# API Endpoints Reference

Complete reference for all application endpoints.

## Base URL

```
http://<ALB_DNS_NAME>
```

Get your ALB URL:
```bash
cd terraform && terraform output -raw alb_url
```

## Standard Endpoints

### GET /

**Description**: Home page with application information

**Response**: 200 OK
```json
{
  "service": "DevOps Agent Demo",
  "version": "1.0.0",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "requestCount": 42,
  "environment": "dev"
}
```

**Example**:
```bash
curl http://<ALB_URL>/
```

---

### GET /health

**Description**: Health check endpoint for monitoring

**Response**: 200 OK (healthy) or 503 Service Unavailable (unhealthy)

**Healthy Response**:
```json
{
  "status": "healthy",
  "uptime": 123.456,
  "memory": {
    "rss": 45678912,
    "heapTotal": 12345678,
    "heapUsed": 8901234,
    "external": 1234567
  },
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

**Unhealthy Response**:
```json
{
  "status": "unhealthy",
  "reason": "Service degraded"
}
```

**Example**:
```bash
curl http://<ALB_URL>/health
```

**Used By**:
- ALB target group health checks
- Monitoring systems
- Kubernetes liveness probes (if migrated)

---

### GET /metrics

**Description**: Prometheus-compatible metrics endpoint

**Response**: 200 OK (text/plain)

**Example Response**:
```
# HELP http_request_duration_seconds Duration of HTTP requests in seconds
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.005",method="GET",route="/",status_code="200"} 10
http_request_duration_seconds_bucket{le="0.01",method="GET",route="/",status_code="200"} 15
...

# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/",status_code="200"} 42

# HELP process_cpu_user_seconds_total Total user CPU time spent in seconds
# TYPE process_cpu_user_seconds_total counter
process_cpu_user_seconds_total 1.234

# HELP nodejs_heap_size_total_bytes Process heap size from Node.js in bytes
# TYPE nodejs_heap_size_total_bytes gauge
nodejs_heap_size_total_bytes 12345678
```

**Example**:
```bash
curl http://<ALB_URL>/metrics
```

**Used By**:
- Prometheus scraping
- CloudWatch metric collection
- Custom monitoring dashboards

---

## Error Testing Endpoints

### GET /error/500

**Description**: Triggers an intentional 500 Internal Server Error

**Response**: 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "Something went wrong!"
}
```

**Side Effects**:
- Logs ERROR level message
- Increments error counter
- Triggers 5XX alarm after threshold

**Example**:
```bash
curl http://<ALB_URL>/error/500
```

**Use Case**: Test error monitoring and alerting

---

### GET /error/timeout

**Description**: Simulates a database timeout (30 second delay)

**Response**: 504 Gateway Timeout (after 30 seconds)
```json
{
  "error": "Gateway Timeout",
  "message": "Database query timed out"
}
```

**Side Effects**:
- Logs ERROR level message
- Blocks for 30 seconds
- Increases response time metrics

**Example**:
```bash
curl http://<ALB_URL>/error/timeout
```

**Warning**: This endpoint will hang for 30 seconds!

**Use Case**: Test timeout handling and latency monitoring

---

### GET /error/memory-leak

**Description**: Intentionally leaks memory by allocating large arrays

**Response**: 200 OK
```json
{
  "message": "Memory leak triggered",
  "arraySize": 100000,
  "memory": {
    "rss": 456789123,
    "heapTotal": 234567890,
    "heapUsed": 123456789,
    "external": 12345678
  }
}
```

**Side Effects**:
- Allocates ~100MB of memory
- Logs WARN level messages
- Triggers memory alarm after multiple calls
- Memory persists until cleared

**Example**:
```bash
curl http://<ALB_URL>/error/memory-leak
```

**Cleanup**:
```bash
curl http://<ALB_URL>/error/clear-memory
```

**Use Case**: Test memory monitoring and OOM scenarios

---

### GET /error/cpu-spike

**Description**: Causes CPU-intensive computation for 5 seconds

**Response**: 200 OK (after 5 seconds)
```json
{
  "message": "CPU spike completed",
  "result": 123456.789,
  "duration": 5000
}
```

**Side Effects**:
- Logs WARN level messages
- Blocks CPU for 5 seconds
- Triggers CPU alarm after multiple concurrent calls

**Example**:
```bash
curl http://<ALB_URL>/error/cpu-spike
```

**Use Case**: Test CPU monitoring and performance degradation

---

### GET /error/disable-health

**Description**: Disables the health check endpoint

**Response**: 200 OK
```json
{
  "message": "Health check disabled"
}
```

**Side Effects**:
- Health endpoint returns 503
- ALB marks targets as unhealthy
- Triggers unhealthy targets alarm
- Affects traffic routing

**Example**:
```bash
curl http://<ALB_URL>/error/disable-health
```

**Restore**:
```bash
curl http://<ALB_URL>/error/enable-health
```

**Warning**: This will cause ALB to stop routing traffic!

**Use Case**: Test health check monitoring and failover

---

### GET /error/enable-health

**Description**: Re-enables the health check endpoint

**Response**: 200 OK
```json
{
  "message": "Health check enabled"
}
```

**Side Effects**:
- Health endpoint returns 200
- ALB marks targets as healthy
- Restores normal traffic routing

**Example**:
```bash
curl http://<ALB_URL>/error/enable-health
```

**Use Case**: Restore health after testing

---

### GET /error/clear-memory

**Description**: Clears memory leak and triggers garbage collection

**Response**: 200 OK
```json
{
  "message": "Memory cleared",
  "clearedItems": 100000,
  "memory": {
    "rss": 45678912,
    "heapTotal": 12345678,
    "heapUsed": 8901234,
    "external": 1234567
  }
}
```

**Side Effects**:
- Clears leaked memory arrays
- Triggers garbage collection (if enabled)
- Logs INFO level message

**Example**:
```bash
curl http://<ALB_URL>/error/clear-memory
```

**Use Case**: Cleanup after memory leak testing

---

## Response Codes

| Code | Meaning | Endpoints |
|------|---------|-----------|
| 200 | OK | /, /metrics, /error/memory-leak, /error/cpu-spike, /error/disable-health, /error/enable-health, /error/clear-memory |
| 404 | Not Found | Any undefined route |
| 500 | Internal Server Error | /error/500 |
| 503 | Service Unavailable | /health (when disabled) |
| 504 | Gateway Timeout | /error/timeout |

## Headers

### Request Headers

**Optional**:
- `User-Agent`: Logged for request tracking
- `X-Forwarded-For`: Client IP (set by ALB)

### Response Headers

**Standard**:
- `Content-Type: application/json` (most endpoints)
- `Content-Type: text/plain` (/metrics)
- `X-Powered-By: Express` (default)

## Rate Limiting

**Current**: No rate limiting implemented

**Recommendation**: Add rate limiting for production use

## Authentication

**Current**: No authentication required

**Recommendation**: Add authentication for production use

## CORS

**Current**: CORS not configured

**Recommendation**: Configure CORS for browser access

## Testing Examples

### Test All Endpoints

```bash
ALB_URL="http://your-alb-url"

# Standard endpoints
curl $ALB_URL/
curl $ALB_URL/health
curl $ALB_URL/metrics

# Error endpoints
curl $ALB_URL/error/500
curl $ALB_URL/error/memory-leak
curl $ALB_URL/error/cpu-spike

# Cleanup
curl $ALB_URL/error/clear-memory
```

### Load Testing

```bash
# Using Apache Bench
ab -n 1000 -c 10 http://<ALB_URL>/

# Using curl in loop
for i in {1..100}; do
  curl -s http://<ALB_URL>/ > /dev/null &
done
wait
```

### Error Spike Test

```bash
# Trigger 20 errors
for i in {1..20}; do
  curl -s http://<ALB_URL>/error/500 > /dev/null &
done
wait
```

## Monitoring

### CloudWatch Metrics

Each endpoint generates:
- Request count
- Response time
- Error rate
- Status code distribution

### CloudWatch Logs

Each request logs:
```json
{
  "timestamp": "2024-01-01T12:00:00.000Z",
  "method": "GET",
  "path": "/",
  "ip": "10.0.1.123",
  "userAgent": "curl/7.68.0"
}
```

Errors log:
```json
{
  "level": "ERROR",
  "message": "Intentional 500 error triggered",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "stack": "Error: ...\n    at ..."
}
```

## Best Practices

### For Testing
1. Test one scenario at a time
2. Wait for alarms to clear between tests
3. Always cleanup after testing
4. Monitor CloudWatch during tests

### For Production
1. Add authentication
2. Implement rate limiting
3. Configure CORS
4. Add request validation
5. Remove error testing endpoints
6. Add API versioning
7. Implement caching

## Troubleshooting

### Endpoint Not Responding

**Check**:
```bash
# Verify ALB is accessible
curl -I http://<ALB_URL>/

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>

# View logs
aws logs tail /ecs/devops-agent-demo-dev --follow
```

### Slow Response Times

**Check**:
```bash
# Measure response time
curl -w "@curl-format.txt" -o /dev/null -s http://<ALB_URL>/

# curl-format.txt:
time_namelookup:  %{time_namelookup}\n
time_connect:  %{time_connect}\n
time_starttransfer:  %{time_starttransfer}\n
time_total:  %{time_total}\n
```

### Errors in Logs

**Check**:
```bash
# Filter for errors
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "ERROR"
```

## Additional Resources

- [Express.js Documentation](https://expressjs.com/)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)
- [AWS ALB Health Checks](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
