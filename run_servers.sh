#!/bin/bash

# Kill existing python services if running (simple cleanup)
pkill -f "SympyService.py"
pkill -f "ocr_service.py"

echo "Starting SymPy Service on port 8001..."
python3 PythonBridge/SympyService.py --port 8001 &

echo "Starting OCR Service on port 3001..."
python3 PythonOCR/ocr_service.py --port 3001 &

echo "Services started."
echo "SymPy: http://127.0.0.1:8001"
echo "OCR:   http://127.0.0.1:3001"
echo "Press Ctrl+C to stop."

wait
