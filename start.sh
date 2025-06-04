#!/bin/bash

# NutriGuide Project Quick Start Script
# Usage: ./start.sh [environment] [service]
# Example: ./start.sh dev all

echo "🍎 NutriGuide Project Quick Start"
echo "Delegating to backend services..."
echo "========================================"

# Forward all arguments to the backend start script
exec ./scripts/start.sh "$@" 