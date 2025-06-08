#!/bin/bash

# NutriGuide Frontend Startup Script

echo "🚀 Starting NutriGuide Frontend..."
echo ""

# Check if frontend directory exists
if [ ! -d "frontend" ]; then
    echo "❌ Frontend directory not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Navigate to frontend directory
cd frontend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    npm install
    echo ""
fi

# Display startup information
echo "🔧 Frontend Configuration:"
echo "   - Technology: React + TypeScript + Vite + Tailwind CSS"
echo "   - Development Port: 4000"
echo "   - QA Port: 4001" 
echo "   - Production Port: 4002"
echo "   - API Endpoint: http://localhost:3000"
echo ""

echo "🌐 Starting frontend development server..."
echo "   Frontend will be available at: http://localhost:4000"
echo "   Press Ctrl+C to stop the server"
echo ""

# Start the development server
npm run dev
