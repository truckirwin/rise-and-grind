#!/bin/bash
echo "🚀 Setting up Rise and Grind Instance (Instance B)"
echo "================================================"
DEVICE_UDID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep -v Max | head -1 | grep -o '[A-F0-9-]\{36\}')
if [ -z "$DEVICE_UDID" ]; then
    echo "❌ ERROR: iPhone 16 Pro not found!"
    xcrun simctl list devices available
    exit 1
fi
export DEVICE_UDID=$DEVICE_UDID
export DEVICE_NAME="iPhone 16 Pro"
export PROJECT_PATH="/Users/truckirwin/Desktop/PROJECTS/Rise and Grind"
export APP_NAME="RiseAndGrind"
echo "✅ Instance B (Rise and Grind) configured:"
echo "   Device: $DEVICE_NAME"
echo "   UDID: $DEVICE_UDID" 
echo "   Project: $PROJECT_PATH"
echo ""
echo "🔒 ISOLATION ACTIVE: This instance will ONLY use iPhone 16 Pro"
echo "⚠️  NEVER shutdown iPhone 16 Pro Max (that's for Motivation AI)"
echo ""
echo "🎯 Ready! Now run your simulator workflow." 