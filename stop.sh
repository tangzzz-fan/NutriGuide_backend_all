#!/bin/bash

# NutriGuide Project Quick Stop Script
# Usage: ./stop.sh [environment] [cleanup]
# Example: ./stop.sh dev cleanup

echo "🍎 NutriGuide Project Quick Stop"
echo "Delegating to backend services..."
echo "========================================"

# Forward all arguments to the backend stop script
exec ./scripts/stop.sh "$@" 