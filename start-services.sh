#!/bin/bash

echo "🚀 Starting Port Forwards for Staging and Production..."
echo ""

# Kill any existing port-forwards
pkill -f "port-forward.*staging-nodejs-app" 2>/dev/null
pkill -f "port-forward.*production-nodejs-app" 2>/dev/null

# Start staging port-forward
echo "📦 Starting Staging on port 30690..."
kubectl port-forward -n staging svc/staging-nodejs-app 30690:80 > /tmp/staging-pf.log 2>&1 &
STAGING_PID=$!

# Start production port-forward
echo "📦 Starting Production on port 30699..."
kubectl port-forward -n production svc/production-nodejs-app 30699:80 > /tmp/production-pf.log 2>&1 &
PRODUCTION_PID=$!

# Wait a moment for port-forwards to establish
sleep 3

# Test the connections
echo ""
echo "🧪 Testing connections..."
echo ""

if curl -s http://localhost:30690/health > /dev/null 2>&1; then
    echo "✅ Staging is accessible at http://localhost:30690"
    echo "   • Health:  http://localhost:30690/health"
    echo "   • Users:   http://localhost:30690/api/users"
    echo "   • Data:    http://localhost:30690/api/data"
else
    echo "❌ Staging is not responding"
fi

echo ""

if curl -s http://localhost:30699/health > /dev/null 2>&1; then
    echo "✅ Production is accessible at http://localhost:30699"
    echo "   • Health:  http://localhost:30699/health"
    echo "   • Users:   http://localhost:30699/api/users"
    echo "   • Data:    http://localhost:30699/api/data"
else
    echo "❌ Production is not responding"
fi

echo ""
echo "📝 Port-forward PIDs:"
echo "   Staging:    $STAGING_PID"
echo "   Production: $PRODUCTION_PID"
echo ""
echo "💡 To stop the port-forwards, run:"
echo "   kill $STAGING_PID $PRODUCTION_PID"
echo ""
echo "   Or run: ./stop-services.sh"
echo ""
echo "🌐 Keep this terminal open to maintain the connections!"
echo ""

# Save PIDs to file for stop script
echo "$STAGING_PID" > /tmp/staging-pf.pid
echo "$PRODUCTION_PID" > /tmp/production-pf.pid

# Wait for user interrupt
trap "echo ''; echo '🛑 Stopping port-forwards...'; kill $STAGING_PID $PRODUCTION_PID 2>/dev/null; rm -f /tmp/staging-pf.pid /tmp/production-pf.pid /tmp/staging-pf.log /tmp/production-pf.log; echo '✅ Stopped'; exit 0" INT TERM

echo "Press Ctrl+C to stop..."
wait
