#!/bin/bash
# Complete Viewport Lock Test - Validates TOTAL freeze mode behavior
# Tests the new grid-level auto_scroll control implementation

set -e

ALACRITTY="./target/release/alacritty"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Complete Viewport Lock Test - Auto-Scroll Feature       ║${NC}"
echo -e "${BLUE}║  Testing TOTAL viewport freeze (even when at bottom)     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "$ALACRITTY" ]; then
    echo -e "${RED}✗ Binary not found: $ALACRITTY${NC}"
    echo "Run: cargo build --release"
    exit 1
fi

echo -e "${GREEN}✓ Binary found${NC}"
echo ""

# Test 1: Default behavior (auto_scroll enabled)
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 1: Default Behavior (auto_scroll=true)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Expected behavior:"
echo "  • Viewport at bottom → NEW OUTPUT FOLLOWS (viewport scrolls)"
echo "  • Typing 'x' while scrolled up → viewport SNAPS BACK to bottom"
echo ""
echo "Test procedure:"
echo "  1. Run: seq 1 100 (generates scrolling content)"
echo "  2. STAY AT BOTTOM - observe viewport follows new output ✓"
echo "  3. Scroll up with Ctrl+Shift+PageUp"
echo "  4. Type 'x' - observe snap-back to bottom ✓"
echo ""
read -p "Press ENTER to launch Alacritty (default config)..."
$ALACRITTY -e bash &
ALACRITTY_PID=$!
echo -e "${GREEN}Alacritty launched (PID: $ALACRITTY_PID)${NC}"
echo ""
read -p "After testing, press ENTER to continue..."
kill $ALACRITTY_PID 2>/dev/null || true
wait $ALACRITTY_PID 2>/dev/null || true
echo ""

# Test 2: Complete viewport lock (auto_scroll disabled via toggle)
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 2: Complete Viewport Lock (toggle to false)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Expected behavior:"
echo "  • After pressing Shift+Ctrl+A (toggle OFF):"
echo "    → Viewport LOCKED even when at bottom"
echo "    → New output does NOT scroll viewport"
echo "    → Typing 'x' does NOT snap back"
echo "  • After pressing Shift+Ctrl+A again (toggle ON):"
echo "    → Normal behavior resumes"
echo ""
echo "Test procedure:"
echo "  1. Press Shift+Ctrl+A to toggle OFF"
echo "  2. Run: seq 1 100"
echo "  3. STAY AT BOTTOM - observe viewport STAYS LOCKED (does not follow) ✓"
echo "  4. Scroll up manually"
echo "  5. Type 'x' - observe viewport STAYS LOCKED (no snap-back) ✓"
echo "  6. Press Shift+Ctrl+A to toggle ON"
echo "  7. Run: seq 1 50"
echo "  8. Observe viewport NOW FOLLOWS output again ✓"
echo ""
read -p "Press ENTER to launch Alacritty..."
$ALACRITTY -e bash &
ALACRITTY_PID=$!
echo -e "${GREEN}Alacritty launched (PID: $ALACRITTY_PID)${NC}"
echo ""
read -p "After testing, press ENTER to continue..."
kill $ALACRITTY_PID 2>/dev/null || true
wait $ALACRITTY_PID 2>/dev/null || true
echo ""

# Test 3: Config file override (starts with auto_scroll disabled)
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 3: Config Override (auto_scroll=false at startup)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Expected behavior:"
echo "  • Starts with viewport LOCKED from boot"
echo "  • No output follows viewport movement"
echo ""
echo "Test procedure:"
echo "  1. Run: seq 1 100"
echo "  2. STAY AT BOTTOM - observe viewport LOCKED from start ✓"
echo "  3. Press Shift+Ctrl+A to toggle ON"
echo "  4. Run: seq 1 50"
echo "  5. Observe viewport NOW follows output ✓"
echo ""
read -p "Press ENTER to launch Alacritty with -o scrolling.auto_scroll=false..."
$ALACRITTY -o scrolling.auto_scroll=false -e bash &
ALACRITTY_PID=$!
echo -e "${GREEN}Alacritty launched with auto_scroll=false (PID: $ALACRITTY_PID)${NC}"
echo ""
read -p "After testing, press ENTER to continue..."
kill $ALACRITTY_PID 2>/dev/null || true
wait $ALACRITTY_PID 2>/dev/null || true
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    TEST COMPLETE                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}All tests completed!${NC}"
echo ""
echo "Expected results summary:"
echo "  ✓ DEFAULT (auto_scroll=true):"
echo "      - Viewport follows output when at bottom"
echo "      - Snap-back on typing when scrolled up"
echo ""
echo "  ✓ LOCKED (auto_scroll=false):"
echo "      - Viewport NEVER moves (total freeze)"
echo "      - Works via toggle (Shift+Ctrl+A) OR config (-o)"
echo ""
echo "Architecture:"
echo "  • Grid-level control (alacritty_terminal/src/grid/mod.rs:273)"
echo "  • Synced from Display on toggle (alacritty/src/input/mod.rs:408)"
echo "  • Synced from config at startup (alacritty/src/window_context.rs:201)"
echo ""
echo -e "${YELLOW}Pro tip: Check RUST_LOG=debug output for toggle messages${NC}"
