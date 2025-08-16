#!/bin/bash
echo "🧹 Cleaning up simulator session: 1755285595"
xcrun simctl shutdown E6CF5661-D1B7-4CC8-A580-98FC9CA35742 2>/dev/null || true
xcrun simctl delete E6CF5661-D1B7-4CC8-A580-98FC9CA35742 2>/dev/null || true
rm -f .simulator_session
rm -f cleanup_simulator.sh
echo "✅ Cleanup complete"
