# 🛡️ DevGuard System-Wide Integration Plan

## **Objective**: Preserve phrase detection + universal access without per-project setup

## **Current State**
- ✅ **Production-ready VSCode extension** (`devguard-backup-1.0.0.vsix`)
- ✅ **DevGuard scripts** (`/PROJECTS/DevGuard/devguard/`)
- ✅ **Working in NotesGen** (extension installed)
- ❌ **Not deployed to other 16 projects**

## **Strategy: Hybrid Approach**
**VSCode/Cursor** → Extension (phrase detection)  
**Everything else** → Shell commands (manual)  
**File watcher** → Basic auto-detection

---

## **Phase 1: Immediate Setup (15 min)**

### **1.1 Install Extension Universally**
```bash
# Install in VSCode/Cursor for phrase detection
code --install-extension devguard-vscode-extension/devguard-backup-1.0.0.vsix

# Verify installation
code --list-extensions | grep devguard
```

### **1.2 Add Shell Functions**
```bash
# Add to ~/.zshrc
cat >> ~/.zshrc << 'EOF'
# DevGuard Universal Commands
export DEVGUARD_PATH="/Users/truckirwin/Desktop/PROJECTS/DevGuard/devguard"

dg-save() { "$DEVGUARD_PATH/smart-save.sh" "${1:-Manual save}"; }
dg-daily() { "$DEVGUARD_PATH/daily-backup.sh"; }
dg-recover() { "$DEVGUARD_PATH/recover.sh"; }
dg-status() { ls -la ../*_BACKUPS 2>/dev/null || echo "No backups found"; }
EOF

source ~/.zshrc
```

### **1.3 Test Both Systems**
```bash
# Test shell commands
cd "Rise and Grind"
dg-save "Testing shell integration"

# Test extension (open in VSCode, type "that works")
code .
```

---

## **Phase 2: Enhanced Detection (30 min)**

### **2.1 File System Phrase Watcher**
```bash
# Create phrase detection daemon
cat > ~/devguard-watcher.sh << 'EOF'
#!/bin/bash
echo "🛡️ DevGuard phrase watcher started..."

fswatch -r /Users/truckirwin/Desktop/PROJECTS --event Updated | while read file; do
    # Only monitor code files
    if [[ "$file" =~ \.(swift|js|ts|py|md|txt)$ ]]; then
        # Check last few lines for phrases
        recent=$(tail -3 "$file" 2>/dev/null | tr '\n' ' ')
        if echo "$recent" | grep -iE "(that works|perfect|done|fixed|good.*works|excellent)" >/dev/null; then
            echo "🎯 Phrase detected: $(basename "$file")"
            cd "$(dirname "$file")"
            dg-save "Auto: phrase detected in $(basename "$file")"
        fi
    fi
done
EOF

chmod +x ~/devguard-watcher.sh
```

### **2.2 Launch Watcher (Optional)**
```bash
# Run in background
nohup ~/devguard-watcher.sh > ~/devguard-watcher.log 2>&1 &

# Or run manually when needed
~/devguard-watcher.sh
```

---

## **Phase 3: Global VSCode Tasks (10 min)**

### **3.1 Add to VSCode User Settings**
```json
// ~/.vscode/settings.json
{
  "tasks": [
    {
      "label": "DevGuard: Manual Save",
      "type": "shell",
      "command": "dg-save",
      "args": ["VSCode task save"],
      "group": "build",
      "presentation": {"reveal": "silent"}
    }
  ]
}
```

### **3.2 Add Keybindings**
```json
// ~/.vscode/keybindings.json
[
  {
    "key": "cmd+shift+d",
    "command": "workbench.action.tasks.runTask",
    "args": "DevGuard: Manual Save"
  }
]
```

---

## **Phrase Detection Coverage**

| **Environment** | **Auto-Detection** | **Manual Command** |
|-----------------|--------------------|--------------------|
| **VSCode** | ✅ Extension | ✅ `Cmd+Shift+D` |
| **Cursor** | ✅ Extension | ✅ `dg-save` |
| **Xcode** | ⚠️ File watcher | ✅ `dg-save` |
| **Terminal** | ❌ None | ✅ `dg-save` |
| **Any Editor** | ⚠️ File watcher | ✅ `dg-save` |

## **Daily Workflow**
1. **VSCode/Cursor**: Type naturally, say "that works" → auto-saves
2. **Xcode**: `dg-save "Fixed iOS bug"`
3. **Terminal**: `dg-save "Updated scripts"`
4. **End of day**: `dg-daily`

## **Verification Commands**
```bash
# Check DevGuard is working
dg-status
ls -la ../Rise\ and\ Grind_BACKUPS/

# Check extension
code --list-extensions | grep devguard

# Check watcher
ps aux | grep devguard-watcher
```

## **Troubleshooting**
- **Extension not working**: Restart VSCode, check console
- **Shell commands not found**: `source ~/.zshrc`
- **No backups**: Check permissions, verify paths
- **Watcher not detecting**: Check `fswatch` installed (`brew install fswatch`)

---

**Result**: DevGuard available everywhere with phrase detection preserved in primary editors. 