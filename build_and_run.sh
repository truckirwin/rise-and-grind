#!/bin/bash

# =============================================================================
# PROJECT-AWARE BUILD AND RUN SCRIPT
# Builds and launches the current project's app on the unique simulator
# =============================================================================

set -e  # Exit on any error

echo "🔨 Building and Running Current Project"
echo "======================================"

# Load session info
if [ ! -f ".simulator_session" ]; then
    echo "❌ ERROR: No simulator session found. Run ./setup_project_simulator.sh first"
    exit 1
fi

source .simulator_session

echo "📱 Project: $PROJECT_NAME"
echo "🆔 Session: $SESSION_ID"
echo "📟 Device: $DEVICE_NAME"
echo "🔧 Scheme: $SCHEME_NAME"
echo ""

# Auto-detect bundle ID from built app
echo "🔍 Auto-detecting bundle ID..."

# Clean and build first
echo "🧹 Cleaning project..."
xcodebuild clean -scheme "$SCHEME_NAME" -quiet

echo "🔨 Building project..."
xcodebuild build -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,id=$DEVICE_UDID" -quiet

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Build failed"
    exit 1
fi

echo "✅ Build successful"

# Find the built app
DERIVED_DATA_PATH=$(xcodebuild -showBuildSettings -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,id=$DEVICE_UDID" | grep " BUILT_PRODUCTS_DIR = " | sed 's/.*= //')
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "*.app" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ ERROR: Could not find built app"
    exit 1
fi

APP_NAME=$(basename "$APP_PATH" .app)
echo "📱 Found app: $APP_NAME"
echo "📂 App path: $APP_PATH"

# Extract bundle ID from Info.plist
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP_PATH/Info.plist" 2>/dev/null)

if [ -z "$BUNDLE_ID" ]; then
    echo "❌ ERROR: Could not extract bundle ID from app"
    exit 1
fi

echo "📦 Bundle ID: $BUNDLE_ID"
echo ""

# Ensure simulator is running
echo "🔄 Checking simulator status..."
DEVICE_STATE=$(xcrun simctl list devices | grep "$DEVICE_UDID" | grep -o "([^)]*)" | tr -d "()")

if [ "$DEVICE_STATE" != "Booted" ]; then
    echo "🔄 Booting simulator..."
    xcrun simctl boot "$DEVICE_UDID"
    sleep 5
fi

# Open Simulator app
echo "🖥️  Opening Simulator window..."
open -a Simulator

# Wait for simulator to be fully ready
echo "⏳ Waiting for simulator to be ready..."
sleep 3

# Install app
echo "📲 Installing app on simulator..."
xcrun simctl install "$DEVICE_UDID" "$APP_PATH"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to install app"
    exit 1
fi

echo "✅ App installed successfully"

# Launch app
echo "🚀 Launching app..."
xcrun simctl launch "$DEVICE_UDID" "$BUNDLE_ID"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to launch app"
    exit 1
fi

echo ""
echo "🎉 SUCCESS!"
echo "=========="
echo "✅ Project: $PROJECT_NAME"
echo "✅ App: $APP_NAME"
echo "✅ Bundle ID: $BUNDLE_ID"
echo "✅ Running on: $DEVICE_NAME"
echo ""
echo "💡 The app should now be visible in the Simulator window"
echo "🧹 When done testing, run: ./cleanup_simulator.sh"
echo "" 