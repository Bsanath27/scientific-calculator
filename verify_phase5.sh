#!/bin/bash
set -e

echo "=== Phase 5 Verification ==="

# 1. Build App
echo "Building ScientificCalculator..."
xcodebuild build -scheme ScientificCalculator -destination 'platform=macOS' > /dev/null
echo "Build Succeeded!"

# 2. Run NLU Tests
echo "Running NLU Tests..."
xcodebuild test-without-building -scheme ScientificCalculator -destination 'platform=macOS' -only-testing:ScientificCalculatorTests/NLUTests > /dev/null
echo "NLU Tests Passed!"

# 3. Start App in Background
APP_PATH="./build/ScientificCalculator.app/Contents/MacOS/ScientificCalculator"
# Note: xcodebuild output location varies, let's find it or just trust build succeeded and try to find product.
# Actually, xcodebuild outputs to DerivedData by default.
DERIVED_DATA=$(xcodebuild -showBuildSettings | grep -m 1 "BUILD_DIR" | grep -oE "\/.*")
APP_PATH="$DERIVED_DATA/Debug/ScientificCalculator.app/Contents/MacOS/ScientificCalculator"

echo "Starting App at $APP_PATH..."
"$APP_PATH" &
APP_PID=$!
sleep 5

# 4. Test Local API
echo "Testing Local API Server..."
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"text":"derivative of x^2"}' http://localhost:8765)
echo "Response: $RESPONSE"

if [[ "$RESPONSE" == *"2x"* ]]; then
    echo "API Test Passed: 2x found in response"
else
    echo "API Test Failed"
    kill $APP_PID
    exit 1
fi

# 5. Cleanup
kill $APP_PID
echo "=== Verification Complete ==="
