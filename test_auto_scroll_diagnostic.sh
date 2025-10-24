#!/bin/bash
# Automated diagnostic test for auto-scroll feature
# Tests both config option and runtime toggle

set -e

ALACRITTY="./target/release/alacritty"
LOG_FILE="/tmp/alacritty_autoscroll_test.log"

echo "=== Auto-Scroll Diagnostic Test ==="
echo ""

# Test 1: Verify binary accepts -o option
echo "[1/4] Testing config option parsing..."
if $ALACRITTY -o scrolling.auto_scroll=false --version &>/dev/null; then
    echo "  ✓ Config option accepted"
else
    echo "  ✗ Config option failed"
    exit 1
fi

# Test 2: Check if keybinding is registered
echo "[2/4] Checking keybinding registration..."
if rg -q "ToggleAutoScroll" alacritty/src/config/bindings.rs; then
    echo "  ✓ ToggleAutoScroll action found in bindings"
else
    echo "  ✗ ToggleAutoScroll action NOT found"
    exit 1
fi

# Test 3: Verify toggle implementation exists
echo "[3/4] Verifying toggle implementation..."
if rg -q "auto_scroll_enabled" alacritty/src/display/mod.rs && \
   rg -q "ToggleAutoScroll" alacritty/src/input/mod.rs; then
    echo "  ✓ Toggle implementation found"
else
    echo "  ✗ Toggle implementation missing"
    exit 1
fi

# Test 4: Check for snap-back logic
echo "[4/4] Checking snap-back logic..."
if rg -q "self.display.auto_scroll_enabled && display_offset != 0" alacritty/src/event.rs; then
    echo "  ✓ Snap-back logic present"
else
    echo "  ✗ Snap-back logic missing"
    exit 1
fi

echo ""
echo "✅ All diagnostic checks passed!"
echo ""
echo "Next: Manual verification required"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "IMPORTANT: Auto-scroll only affects 'snap-back-on-typing'"
echo ""
echo "Expected Behavior:"
echo "  • Default (auto_scroll=true):"
echo "    1. Scroll up → viewport locks at old content"
echo "    2. Type 'hello' → viewport SNAPS to bottom"
echo ""
echo "  • Disabled (auto_scroll=false or after Shift+Ctrl+A):"
echo "    1. Scroll up → viewport locks at old content"
echo "    2. Type 'hello' → viewport STAYS locked (no snap)"
echo ""
echo "Test Procedure:"
echo "  1. Run: RUST_LOG=warn ./target/release/alacritty"
echo "  2. Generate output: yes | head -100"
echo "  3. Scroll up with PageUp"
echo "  4. Type 'test' → should snap to bottom"
echo "  5. Scroll up again"
echo "  6. Press Shift+Ctrl+A (watch terminal for log message)"
echo "  7. Type 'test' → should NOT snap (stays scrolled)"
echo ""
echo "Run interactive test? [y/N]"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Launching Alacritty with debug logging..."
    echo "Watch for: 'Toggled auto_scroll: true -> false'"
    sleep 2
    
    RUST_LOG=warn $ALACRITTY 2>&1 | tee "$LOG_FILE" &
    ALACRITTY_PID=$!
    
    echo ""
    echo "Alacritty launched (PID: $ALACRITTY_PID)"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Press Enter when done testing..."
    read
    
    if kill -0 $ALACRITTY_PID 2>/dev/null; then
        echo "Alacritty still running. Logs captured at: $LOG_FILE"
    fi
else
    echo "Skipping interactive test."
fi
