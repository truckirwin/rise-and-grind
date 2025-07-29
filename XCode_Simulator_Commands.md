# Xcode iPhone Simulator Command Reference

## 📱 **Rise and Grind App Development - Simulator Workflow**

This document provides a comprehensive reference for all Xcode iPhone simulator commands used during the development of the Rise and Grind motivational job seeker app.

---

## 🚨 **CRITICAL: Instance Isolation Protocol**

### **🔒 Simulator Instance Rules**
- **Rise and Grind:** iPhone 16 Pro ONLY (`F1700F11-8976-4645-A5E5-9B2A7047F9AA`)
- **Motivation AI:** iPhone 16 Pro Max ONLY
- **❌ NEVER use `xcrun simctl shutdown all`** - This kills ALL instances
- **✅ ALWAYS run setup script first** to configure device isolation

### **📋 Required Setup (Run Once Per Session)**

```bash
# Initialize instance isolation
source setup_rise_and_grind.sh
```

## 🚀 **Updated Workflow - Instance-Safe**

After running setup script, execute this **mandatory sequence**:

```bash
# 1. Setup instance isolation (ALWAYS RUN FIRST)
source setup_rise_and_grind.sh

# 2. Stop ONLY our dedicated simulator
xcrun simctl shutdown $DEVICE_UDID

# 3. Clean project build cache
xcodebuild clean -scheme RiseAndGrind

# 4. Boot our dedicated simulator
xcrun simctl boot $DEVICE_UDID

# 5. Open simulator window targeting our device
open -a Simulator --args -CurrentDeviceUDID $DEVICE_UDID

# 6. Build project with device isolation
xcodebuild -scheme RiseAndGrind -destination "id=$DEVICE_UDID" build

# 7. Install app on our dedicated device
xcrun simctl install $DEVICE_UDID "/Users/truckirwin/Library/Developer/Xcode/DerivedData/RiseAndGrind-guehdnlsjuwbithdxzezeymubeeb/Build/Products/Debug-iphonesimulator/RiseAndGrind.app"

# 8. Launch app on our dedicated device
xcrun simctl launch $DEVICE_UDID com.truckirwin.riseandgrind.app
```

### **⚡ One-Command Workflow (After Initial Setup)**

```bash
source setup_rise_and_grind.sh && xcrun simctl shutdown $DEVICE_UDID && xcodebuild clean -scheme RiseAndGrind && xcrun simctl boot $DEVICE_UDID && open -a Simulator --args -CurrentDeviceUDID $DEVICE_UDID && xcodebuild -scheme RiseAndGrind -destination "id=$DEVICE_UDID" build && xcrun simctl install $DEVICE_UDID "/Users/truckirwin/Library/Developer/Xcode/DerivedData/RiseAndGrind-guehdnlsjuwbithdxzezeymubeeb/Build/Products/Debug-iphonesimulator/RiseAndGrind.app" && xcrun simctl launch $DEVICE_UDID com.truckirwin.riseandgrind.app
```

---

## 📋 **Command Categories**

### **1. Simulator Management**

#### Stop All Simulators
```bash
xcrun simctl shutdown all
```
- **Purpose:** Ensures clean state by stopping all running simulators
- **Usage:** Always run first in workflow to prevent conflicts
- **Output:** No output if successful

#### Boot Specific Simulator
```bash
xcrun simctl boot F1700F11-8976-4645-A5E5-9B2A7047F9AA
```
- **Purpose:** Starts the iPhone 16 Pro simulator
- **Device:** iPhone 16 Pro (Device ID: `F1700F11-8976-4645-A5E5-9B2A7047F9AA`)
- **Output:** Success message or device already booted

#### Open Simulator Window
```bash
open -a Simulator
```
- **Purpose:** Opens the Simulator app with visible window
- **Required:** Essential for visual testing and interaction
- **Note:** Must run after booting device

---

### **2. Project Build Commands**

#### Clean Build Cache
```bash
xcodebuild clean -scheme RiseAndGrind
```
- **Purpose:** Removes cached build artifacts to ensure fresh compilation
- **Prevents:** Stale build issues and outdated dependencies
- **Output:** Confirmation of clean operation

#### Build for Simulator
```bash
xcodebuild -scheme RiseAndGrind -destination 'platform=iOS Simulator,id=F1700F11-8976-4645-A5E5-9B2A7047F9AA' build
```
- **Purpose:** Compiles the Rise and Grind app for iOS simulator
- **Target:** iPhone 16 Pro simulator specifically
- **Output:** Build success/failure with detailed error messages if any
- **Build Path:** `/Users/truckirwin/Library/Developer/Xcode/DerivedData/RiseAndGrind-guehdnlsjuwbithdxzezeymubeeb/Build/Products/Debug-iphonesimulator/`

---

### **3. App Deployment**

#### Install App on Simulator
```bash
xcrun simctl install F1700F11-8976-4645-A5E5-9B2A7047F9AA "/Users/truckirwin/Library/Developer/Xcode/DerivedData/RiseAndGrind-guehdnlsjuwbithdxzezeymubeeb/Build/Products/Debug-iphonesimulator/RiseAndGrind.app"
```
- **Purpose:** Installs the compiled app bundle on the simulator
- **Requires:** Successful build completion first
- **Output:** Installation confirmation

#### Launch App
```bash
xcrun simctl launch F1700F11-8976-4645-A5E5-9B2A7047F9AA com.truckirwin.riseandgrind.app
```
- **Purpose:** Starts the Rise and Grind app on the simulator
- **Bundle ID:** `com.truckirwin.riseandgrind.app`
- **Output:** Process ID and launch confirmation

---

## 🔧 **Project Configuration**

### **App Details**
- **Project Name:** RiseAndGrind
- **Scheme:** RiseAndGrind
- **Bundle Identifier:** com.truckirwin.riseandgrind.app
- **Target Platform:** iOS Simulator
- **Development Team:** truckirwin

### **Simulator Configuration**
- **Device Model:** iPhone 16 Pro
- **Device ID:** F1700F11-8976-4645-A5E5-9B2A7047F9AA
- **iOS Version:** Latest available
- **Display:** Retina 6.1-inch

### **File Paths**
- **Project Root:** `/Users/truckirwin/Desktop/PROJECTS/Rise and Grind/`
- **Build Products:** `/Users/truckirwin/Library/Developer/Xcode/DerivedData/RiseAndGrind-guehdnlsjuwbithdxzezeymubeeb/Build/Products/Debug-iphonesimulator/`
- **App Bundle:** `RiseAndGrind.app`

---

## 📱 **Setup Script Installation**

### **🔥 One-Command Setup (Run Once)**

```bash
cd "/Users/truckirwin/Desktop/PROJECTS/Rise and Grind" && cat > setup_rise_and_grind.sh << 'EOF'
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
EOF
chmod +x setup_rise_and_grind.sh && source setup_rise_and_grind.sh
```

### **✅ Test Isolation**

```bash
echo "My device: $DEVICE_NAME ($DEVICE_UDID)" && xcrun simctl list devices | grep "Booted"
```

## ⚡ **Workflow Best Practices - UPDATED**

### **🚨 Critical Instance Isolation Rules**
1. **ALWAYS** run `source setup_rise_and_grind.sh` first
2. **NEVER** use `xcrun simctl shutdown all` - kills all instances
3. **ONLY** shutdown your specific device: `xcrun simctl shutdown $DEVICE_UDID`
4. **ALWAYS** use `$DEVICE_UDID` variable for device targeting
5. **VERIFY** isolation with device listing before major operations

### **Legacy Rules (Still Important)**
1. **Always** clean build to avoid cached issues
2. **Always** boot simulator before building
3. **Always** open simulator window for visual confirmation
4. **Never** skip steps - this prevents 90% of build issues

### **Error Prevention**
- **Clean builds** eliminate most compilation errors
- **Simulator restart** resolves memory and state issues
- **Sequential execution** prevents race conditions
- **Window opening** ensures UI testing capability

### **Performance Tips**
- Run commands in **exact order** shown
- Wait for each command to **complete** before next
- **Visual confirmation** in simulator before testing
- **Monitor build output** for early error detection

---

## 🐛 **Troubleshooting Common Issues**

### **Build Failures**
```bash
# If build fails, try extended clean:
rm -rf ~/Library/Developer/Xcode/DerivedData/RiseAndGrind*
xcodebuild clean -scheme RiseAndGrind
```

### **Simulator Issues**
```bash
# If simulator won't boot:
xcrun simctl erase F1700F11-8976-4645-A5E5-9B2A7047F9AA
xcrun simctl boot F1700F11-8976-4645-A5E5-9B2A7047F9AA
```

### **App Launch Problems**
```bash
# If app won't launch, try uninstall/reinstall:
xcrun simctl uninstall F1700F11-8976-4645-A5E5-9B2A7047F9AA com.truckirwin.riseandgrind.app
# Then run normal install/launch sequence
```

---

## 📊 **Success Indicators**

### **Build Success**
- ✅ `BUILD SUCCEEDED` message
- ✅ No compilation errors
- ✅ App bundle created in DerivedData

### **Install Success**
- ✅ No error messages during install
- ✅ App icon appears on simulator home screen

### **Launch Success**
- ✅ App opens with splash screen
- ✅ Navigation works correctly
- ✅ Audio plays for motivational messages
- ✅ All tabs functional (Home, Let's Go!, Tasks, Learn, Profile)

---

## 🎯 **Development Notes**

### **Key Features Tested**
- **TikTok-style motivational messages** with audio
- **Technical activity graphs** with time series data
- **Tabbed profile interface** with preferences
- **Auto-play first message** on app launch
- **MainTabView navigation** with 5 tabs

### **Critical Workflows**
- Every code change requires **complete rebuild sequence**
- UI changes need **visual verification** in simulator
- Audio features require **simulator sound testing**
- Performance testing needs **clean environment**

---

*Last Updated: $(date)*
*Project: Rise and Grind - Motivational Job Seeker App*
*Platform: iOS Simulator (iPhone 16 Pro)* 