#!/bin/bash
echo "🛡️ DevGuard phrase watcher started..."

fswatch -r /Users/truckirwin/Desktop/PROJECTS --event Updated | while read file; do
    # Only monitor code files
    if [[ "$file" =~ \.(swift|js|ts|py|md|txt)$ ]]; then
        # Check last few lines for phrases
        recent=$(tail -3 "$file" 2>/dev/null | tr '\n' ' ')
        if echo "$recent" | grep -iE "(that works|perfect|done|fixed|good.*works|excellent|push it)" >/dev/null; then
            echo "🎯 Phrase detected: $(basename "$file")"
            cd "$(dirname "$file")"
            dg-save "Auto: phrase detected in $(basename "$file")"
        fi
    fi
done 