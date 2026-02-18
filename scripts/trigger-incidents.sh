#!/bin/bash

# Incident Trigger Script for Testing DevOps Agent
# This script triggers various incident scenarios for testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get ALB URL from Terraform output
cd terraform
ALB_URL=$(terraform output -raw alb_url 2>/dev/null || echo "")
cd ..

if [ -z "$ALB_URL" ]; then
    echo -e "${RED}Error: Could not retrieve ALB URL from Terraform${NC}"
    echo "Please ensure infrastructure is deployed"
    exit 1
fi

echo -e "${GREEN}=== DevOps Agent Incident Trigger ===${NC}"
echo "Application URL: $ALB_URL"
echo ""

# Function to trigger error spike
trigger_error_spike() {
    echo -e "${YELLOW}Triggering error spike...${NC}"
    for i in {1..20}; do
        curl -s "$ALB_URL/error/500" > /dev/null &
        echo -n "."
    done
    wait
    echo ""
    echo -e "${GREEN}✓ Error spike triggered (20 requests)${NC}"
    echo "Expected: High 5XX error alarm should trigger"
}

# Function to trigger memory leak
trigger_memory_leak() {
    echo -e "${YELLOW}Triggering memory leak...${NC}"
    for i in {1..5}; do
        curl -s "$ALB_URL/error/memory-leak" > /dev/null
        echo "Memory leak iteration $i/5"
        sleep 2
    done
    echo -e "${GREEN}✓ Memory leak triggered${NC}"
    echo "Expected: High memory utilization alarm should trigger"
}

# Function to trigger CPU spike
trigger_cpu_spike() {
    echo -e "${YELLOW}Triggering CPU spike...${NC}"
    for i in {1..3}; do
        curl -s "$ALB_URL/error/cpu-spike" > /dev/null &
        echo "CPU spike iteration $i/3"
    done
    wait
    echo -e "${GREEN}✓ CPU spike triggered${NC}"
    echo "Expected: High CPU utilization alarm should trigger"
}

# Function to trigger health check failure
trigger_health_failure() {
    echo -e "${YELLOW}Triggering health check failure...${NC}"
    curl -s "$ALB_URL/error/disable-health" > /dev/null
    echo -e "${GREEN}✓ Health check disabled${NC}"
    echo "Expected: Unhealthy targets alarm should trigger"
    echo ""
    echo -e "${YELLOW}Waiting 60 seconds for health checks to fail...${NC}"
    sleep 60
    echo ""
    echo "To restore health:"
    echo "  curl $ALB_URL/error/enable-health"
}

# Function to trigger timeout
trigger_timeout() {
    echo -e "${YELLOW}Triggering database timeout...${NC}"
    curl -s "$ALB_URL/error/timeout" > /dev/null &
    echo -e "${GREEN}✓ Timeout triggered (will complete in 30s)${NC}"
    echo "Expected: Increased response time metrics"
}

# Function to show current status
show_status() {
    echo -e "${YELLOW}Current Application Status:${NC}"
    echo ""
    
    # Health check
    HEALTH=$(curl -s "$ALB_URL/health" | jq -r '.status' 2>/dev/null || echo "unknown")
    if [ "$HEALTH" == "healthy" ]; then
        echo -e "Health: ${GREEN}$HEALTH${NC}"
    else
        echo -e "Health: ${RED}$HEALTH${NC}"
    fi
    
    # Metrics
    echo ""
    echo "Metrics endpoint: $ALB_URL/metrics"
    echo ""
    
    # Recent logs
    echo -e "${YELLOW}Checking CloudWatch alarms...${NC}"
    aws cloudwatch describe-alarms \
        --alarm-name-prefix "devops-agent-demo" \
        --state-value ALARM \
        --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' \
        --output table 2>/dev/null || echo "No alarms in ALARM state"
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    curl -s "$ALB_URL/error/enable-health" > /dev/null
    curl -s "$ALB_URL/error/clear-memory" > /dev/null
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Main menu
case "${1:-}" in
    error-spike)
        trigger_error_spike
        ;;
    memory-leak)
        trigger_memory_leak
        ;;
    cpu-spike)
        trigger_cpu_spike
        ;;
    health-failure)
        trigger_health_failure
        ;;
    timeout)
        trigger_timeout
        ;;
    status)
        show_status
        ;;
    cleanup)
        cleanup
        ;;
    all)
        echo -e "${YELLOW}Running all incident scenarios...${NC}"
        echo ""
        trigger_error_spike
        sleep 10
        trigger_cpu_spike
        sleep 10
        trigger_memory_leak
        echo ""
        echo -e "${GREEN}All scenarios triggered${NC}"
        ;;
    *)
        echo "Usage: $0 {error-spike|memory-leak|cpu-spike|health-failure|timeout|status|cleanup|all}"
        echo ""
        echo "Scenarios:"
        echo "  error-spike     - Trigger multiple 500 errors"
        echo "  memory-leak     - Cause memory leak in application"
        echo "  cpu-spike       - Cause CPU utilization spike"
        echo "  health-failure  - Disable health checks"
        echo "  timeout         - Trigger database timeout"
        echo "  status          - Show current application status"
        echo "  cleanup         - Restore application to healthy state"
        echo "  all             - Run all scenarios (except health-failure)"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Monitor the investigation in AWS DevOps Agent console${NC}"
echo "CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/\$252Fecs\$252Fdevops-agent-demo-dev"
