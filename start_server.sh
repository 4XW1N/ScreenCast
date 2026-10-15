#!/bin/bash
# Start the ScreenCast signaling server

cd "$(dirname "$0")/server"

if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

echo "Starting signaling server on port 8888..."
echo "Health check on port 8889"
echo ""
echo "Find your IP with: ifconfig | grep 'inet ' | grep -v 127.0.0.1"
echo ""

npm start