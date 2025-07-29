#!/bin/bash

# =============================================================================
# PROJECT-AWARE SIMULATOR SETUP SCRIPT
# Creates unique simulator sessions and auto-detects current project
# =============================================================================

set -e  # Exit on any error

# Get current working directory and project name
CURRENT_DIR=$(pwd)
PROJECT_NAME=$(basename "$CURRENT_DIR")
SESSION_ID=$(date +%s)  # Unix timestamp for uniqueness

echo "🚀 Setting up unique simulator session for: $PROJECT_NAME"
echo "============================================================"
echo "📍 Working Directory: $CURRENT_DIR"
echo "🆔 Session ID: $SESSION_ID"
echo ""

# Auto-detect Xcode project
XCODE_PROJECT=$(find . -maxdepth 1 -name "*.xcodeproj" | head -1)
if [ -z "$XCODE_PROJECT" ]; then
    echo "❌ ERROR: No .xcodeproj found in current directory"
    exit 1
fi

PROJECT_FILE=$(basename "$XCODE_PROJECT" .xcodeproj)
echo "📱 Detected Project: $PROJECT_FILE"

# Auto-detect app scheme/bundle
SCHEME_NAME="$PROJECT_FILE"
BUNDLE_ID_BASE=$(echo "$PROJECT_FILE" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

echo "🔧 Scheme: $SCHEME_NAME"
echo "📦 Bundle Base: $BUNDLE_ID_BASE"
echo ""

# Create unique simulator device
UNIQUE_DEVICE_NAME="${PROJECT_NAME}_Sim_${SESSION_ID}"
echo "🏗️  Creating unique simulator device: $UNIQUE_DEVICE_NAME"

# Create new iPhone 16 Pro device with unique name
DEVICE_UDID=$(xcrun simctl create "$UNIQUE_DEVICE_NAME" "iPhone 16 Pro" "com.apple.CoreSimulator.SimRuntime.iOS-18-5")

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to create simulator device"
    exit 1
fi

echo "✅ Created device: $UNIQUE_DEVICE_NAME"
echo "🆔 Device UDID: $DEVICE_UDID"
echo ""

# Export environment variables
export PROJECT_DIR="$CURRENT_DIR"
export PROJECT_NAME="$PROJECT_NAME"
export SCHEME_NAME="$SCHEME_NAME"
export DEVICE_UDID="$DEVICE_UDID"
export DEVICE_NAME="$UNIQUE_DEVICE_NAME"
export SESSION_ID="$SESSION_ID"

# Create session info file
cat > ".simulator_session" << EOF
SESSION_ID="$SESSION_ID"
PROJECT_NAME="$PROJECT_NAME"
SCHEME_NAME="$SCHEME_NAME"
DEVICE_UDID="$DEVICE_UDID"
DEVICE_NAME="$UNIQUE_DEVICE_NAME"
PROJECT_DIR="$CURRENT_DIR"
CREATED="$(date)"
EOF

echo "💾 Session info saved to .simulator_session"
echo ""

# Create cleanup script
cat > "cleanup_simulator.sh" << EOF
#!/bin/bash
echo "🧹 Cleaning up simulator session: $SESSION_ID"
xcrun simctl shutdown $DEVICE_UDID 2>/dev/null || true
xcrun simctl delete $DEVICE_UDID 2>/dev/null || true
rm -f .simulator_session
rm -f cleanup_simulator.sh
echo "✅ Cleanup complete"
EOF

chmod +x cleanup_simulator.sh

echo "🧹 Cleanup script created: ./cleanup_simulator.sh"
echo ""

# Boot the new device
echo "🔄 Booting simulator device..."
xcrun simctl boot "$DEVICE_UDID"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to boot simulator"
    exit 1
fi

echo "✅ Simulator booted successfully"
echo ""

echo "🎯 SIMULATOR SESSION READY!"
echo "=========================="
echo "Device: $UNIQUE_DEVICE_NAME"
echo "UDID: $DEVICE_UDID"
echo "Project: $PROJECT_NAME"
echo "Scheme: $SCHEME_NAME"
echo ""
echo "💡 Next steps:"
echo "   1. Run: open -a Simulator"
echo "   2. Run: ./build_and_run.sh"
echo "   3. When done: ./cleanup_simulator.sh"
echo "" 