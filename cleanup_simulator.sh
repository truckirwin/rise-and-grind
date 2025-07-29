#!/bin/bash
echo "🧹 Cleaning up simulator session: 1753718089"
xcrun simctl shutdown AC7BA702-9815-46FB-9173-3C2B81F8ABA2 2>/dev/null || true
xcrun simctl delete AC7BA702-9815-46FB-9173-3C2B81F8ABA2 2>/dev/null || true
rm -f .simulator_session
rm -f cleanup_simulator.sh
echo "✅ Cleanup complete"
