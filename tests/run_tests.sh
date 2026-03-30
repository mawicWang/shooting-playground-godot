#!/bin/bash
# 运行效果验证测试
# Usage: ./tests/run_tests.sh

cd "$(dirname "$0")/.."

echo "Running effect test harness..."
godot --headless --script res://tests/effect_test_harness.gd

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
else
    echo ""
    echo "❌ Tests failed!"
fi

exit $exit_code
