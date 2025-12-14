#!/bin/bash

echo "🛑 Stopping port-forwards..."

# Kill port-forwards by PID if files exist
if [ -f /tmp/staging-pf.pid ]; then
    STAGING_PID=$(cat /tmp/staging-pf.pid)
    kill $STAGING_PID 2>/dev/null && echo "✅ Stopped staging port-forward (PID: $STAGING_PID)"
    rm -f /tmp/staging-pf.pid
fi

if [ -f /tmp/production-pf.pid ]; then
    PRODUCTION_PID=$(cat /tmp/production-pf.pid)
    kill $PRODUCTION_PID 2>/dev/null && echo "✅ Stopped production port-forward (PID: $PRODUCTION_PID)"
    rm -f /tmp/production-pf.pid
fi

# Also kill by process name as backup
pkill -f "port-forward.*staging-nodejs-app" 2>/dev/null
pkill -f "port-forward.*production-nodejs-app" 2>/dev/null

# Clean up log files
rm -f /tmp/staging-pf.log /tmp/production-pf.log

echo "✅ All port-forwards stopped"
