
#!/bin/bash

# ==========================================
# PAYFX GLOBAL - CONSOLIDATED TEST RUNNER
# ==========================================

mkdir -p build/reports

REPORT="build/reports/test-summary.txt"

echo "=========================================="
echo "       PAYFX GLOBAL TEST EXECUTION"
echo "=========================================="

{
  echo "PAYFX GLOBAL - TEST EXECUTION REPORT"
  echo "Date: $(date)"
  echo "=========================================="
} > "$REPORT"

run_suite() {
    NAME="$1"
    TEST_PATH="$2"
    LOG="build/reports/${NAME}_report.txt"

    echo ""
    echo "------------------------------------------"
    echo "Running: $NAME"
    echo "------------------------------------------"

    if [ ! -e "$TEST_PATH" ]; then
        echo "$NAME: NOT CONFIGURED" | tee -a "$REPORT"
        return
    fi

    flutter test "$TEST_PATH" --reporter expanded 2>&1 | tee "$LOG"
    RESULT=${PIPESTATUS[0]}

    if [ "$RESULT" -eq 0 ]; then
        echo "$NAME: PASSED" | tee -a "$REPORT"
    else
        echo "$NAME: FAILED" | tee -a "$REPORT"
    fi
}

# 1. UNIT TESTING
run_suite "Unit" "test/unit"

# 2. WIDGET TESTING
run_suite "Widget_Components" "test/widget"
run_suite "Widget_Root" "test/widget_test.dart"

# 3. API TESTING
run_suite "API" "test/api"

# 4. E2E-STYLE TEST
run_suite "Test_Integration" "test/integration"

# 5. DEVICE INTEGRATION TEST
DEVICE_ID="$1"

if [ -n "$DEVICE_ID" ] && [ -d "integration_test" ]; then

    echo ""
    echo "Running Device Integration Tests..."

    flutter test integration_test \
      -d "$DEVICE_ID" \
      --reporter expanded 2>&1 | tee build/reports/device_integration_report.txt

    RESULT=${PIPESTATUS[0]}

    if [ "$RESULT" -eq 0 ]; then
        echo "Device_Integration: PASSED" | tee -a "$REPORT"
    else
        echo "Device_Integration: FAILED" | tee -a "$REPORT"
    fi
else
    echo "Device_Integration: NOT RUN (device ID required)" | tee -a "$REPORT"
fi

# FINAL SUMMARY
echo ""
echo "=========================================="
echo "       FINAL PAYFX TEST REPORT"
echo "=========================================="

cat "$REPORT"

echo ""
echo "Detailed reports saved in:"
echo "build/reports/"
echo "=========================================="
