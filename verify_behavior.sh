#!/bin/bash
# Comprehensive behavior verification script
# Tests the ACTUAL observable behavior difference

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AUTO-SCROLL BEHAVIOR VERIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  CRITICAL: Auto-scroll ONLY affects snap-back-on-typing"
echo ""
echo "What auto-scroll IS:"
echo "  ✓ Controls viewport snap-back when typing while scrolled up"
echo ""
echo "What auto-scroll is NOT:"
echo "  ✗ Does NOT control following new output"
echo "  ✗ Does NOT prevent scrolling up"
echo "  ✗ Does NOT affect mouse wheel behavior"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if binary exists
if [[ ! -f "./target/release/alacritty" ]]; then
    echo "❌ Binary not found. Building..."
    cargo build --release
fi

echo "Select test mode:"
echo "  1) Visual demonstration (manual)"
echo "  2) Automated behavior analysis"
echo "  3) Debug log verification"
echo "  4) All tests"
echo ""
read -p "Choice [1-4]: " choice

case $choice in
    1|4)
        echo ""
        echo "━━━ TEST 1: Visual Demonstration ━━━"
        echo ""
        echo "This will open Alacritty with instructions."
        echo "You will manually test the snap-back behavior."
        echo ""
        read -p "Press Enter to continue..."
        
        RUST_LOG=warn ./target/release/alacritty -e bash -c '
clear;
echo "╔══════════════════════════════════════════════════════╗";
echo "║     AUTO-SCROLL MANUAL TEST PROCEDURE               ║";
echo "╚══════════════════════════════════════════════════════╝";
echo "";
echo "STEP 1: Generate scrollable content";
echo "  Run: seq 1 100";
echo "";
echo "STEP 2: Test DEFAULT behavior (auto_scroll=true)";
echo "  a) Scroll UP with PageUp (or mouse wheel)";
echo "  b) Type any character (e.g., 'x')";
echo "  c) Observe: Viewport SHOULD snap to bottom";
echo "";
echo "STEP 3: Test TOGGLED behavior";
echo "  a) Scroll UP again";
echo "  b) Press: Shift+Ctrl+A";
echo "  c) Watch for log: \"Toggled auto_scroll: true -> false\"";
echo "  d) Type any character (e.g., 'y')";
echo "  e) Observe: Viewport SHOULD stay scrolled (no snap!)";
echo "";
echo "STEP 4: Verify toggle restoration";
echo "  a) Scroll UP again";
echo "  b) Press: Shift+Ctrl+A";
echo "  c) Watch for log: \"Toggled auto_scroll: false -> true\"";
echo "  d) Type any character";
echo "  e) Observe: Snap-back restored";
echo "";
echo "════════════════════════════════════════════════════════";
echo "";
bash;
' 2>&1 | grep -E "(Toggled|auto_scroll)" &
        ;;
esac

case $choice in
    2|4)
        echo ""
        echo "━━━ TEST 2: Automated Behavior Analysis ━━━"
        echo ""
        echo "Checking implementation completeness..."
        echo ""
        
        # Check 1: Config struct
        if rg -q "pub auto_scroll: bool" alacritty/src/config/scrolling.rs; then
            echo "✓ Config field exists: scrolling.auto_scroll"
        else
            echo "✗ Config field missing!"
            exit 1
        fi
        
        # Check 2: Display field
        if rg -q "auto_scroll_enabled:" alacritty/src/display/mod.rs; then
            echo "✓ Runtime state field exists: Display.auto_scroll_enabled"
        else
            echo "✗ Display field missing!"
            exit 1
        fi
        
        # Check 3: Initialization
        if rg -q "auto_scroll_enabled: config.scrolling.auto_scroll" alacritty/src/display/mod.rs; then
            echo "✓ Initialization correct: reads from config"
        else
            echo "✗ Initialization broken!"
            exit 1
        fi
        
        # Check 4: Snap-back logic
        if rg -q "self.display.auto_scroll_enabled && display_offset != 0" alacritty/src/event.rs; then
            echo "✓ Snap-back logic present"
        else
            echo "✗ Snap-back logic missing!"
            exit 1
        fi
        
        # Check 5: Toggle handler
        if rg -q "Action::ToggleAutoScroll.*auto_scroll_enabled = !old_value" alacritty/src/input/mod.rs -U 5; then
            echo "✓ Toggle handler implemented"
        else
            echo "✗ Toggle handler missing!"
            exit 1
        fi
        
        echo ""
        echo "✅ All implementation checks passed!"
        ;;
esac

case $choice in
    3|4)
        echo ""
        echo "━━━ TEST 3: Debug Log Verification ━━━"
        echo ""
        echo "Testing config initialization..."
        
        # Test with auto_scroll=false
        timeout 2 bash -c "RUST_LOG=alacritty=debug ./target/release/alacritty -o scrolling.auto_scroll=false 2>&1" > /tmp/alacritty_test.log || true
        
        if rg -q "auto_scroll" /tmp/alacritty_test.log 2>/dev/null; then
            echo "✓ Debug logging present in output"
            echo ""
            echo "Relevant logs:"
            rg "auto_scroll" /tmp/alacritty_test.log | head -5
        else
            echo "⚠️  No auto_scroll logs found (may need more activity)"
        fi
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 SUMMARY OF EXPECTED BEHAVIOR:"
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│ Scenario 1: auto_scroll = true (DEFAULT)          │"
echo "├─────────────────────────────────────────────────────┤"
echo "│ • New output appears → follows if at bottom        │"
echo "│ • Scroll up manually → viewport locks              │"
echo "│ • Type while scrolled → SNAPS to bottom ⭐         │"
echo "└─────────────────────────────────────────────────────┘"
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│ Scenario 2: auto_scroll = false (DISABLED)        │"
echo "├─────────────────────────────────────────────────────┤"
echo "│ • New output appears → follows if at bottom        │"
echo "│ • Scroll up manually → viewport locks              │"
echo "│ • Type while scrolled → STAYS locked ⭐            │"
echo "└─────────────────────────────────────────────────────┘"
echo ""
echo "🔑 KEY INSIGHT:"
echo "   The ONLY difference is the snap-back when TYPING."
echo "   If you only watch OUTPUT (not type), no difference!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
