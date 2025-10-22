#!/bin/bash
# Simple verification that implementation is complete

echo "🔍 Auto-Scroll Implementation Verification"
echo ""

checks_passed=0
checks_total=6

# Check 1
if rg -q "pub auto_scroll: bool" alacritty/src/config/scrolling.rs; then
    echo "✅ [1/6] Config struct has auto_scroll field"
    ((checks_passed++))
else
    echo "❌ [1/6] Config struct missing auto_scroll"
fi

# Check 2
if rg -q "auto_scroll_enabled:" alacritty/src/display/mod.rs; then
    echo "✅ [2/6] Display struct has runtime state"
    ((checks_passed++))
else
    echo "❌ [2/6] Display struct missing runtime state"
fi

# Check 3
if rg -q "auto_scroll_enabled: config.scrolling.auto_scroll" alacritty/src/display/mod.rs; then
    echo "✅ [3/6] Initialization from config correct"
    ((checks_passed++))
else
    echo "❌ [3/6] Initialization broken"
fi

# Check 4
if rg -q "if self.display.auto_scroll_enabled && display_offset" alacritty/src/event.rs; then
    echo "✅ [4/6] Snap-back logic implemented"
    ((checks_passed++))
else
    echo "❌ [4/6] Snap-back logic missing"
fi

# Check 5
if rg -q "Action::ToggleAutoScroll" alacritty/src/input/mod.rs; then
    echo "✅ [5/6] Toggle handler exists"
    ((checks_passed++))
else
    echo "❌ [5/6] Toggle handler missing"
fi

# Check 6
if rg -q "ToggleAutoScroll" extra/man/alacritty-bindings.5.scd; then
    echo "✅ [6/6] Documentation updated"
    ((checks_passed++))
else
    echo "❌ [6/6] Documentation missing"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Result: $checks_passed/$checks_total checks passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $checks_passed -eq $checks_total ]; then
    echo "✅ Implementation complete!"
    echo ""
    echo "Next: Manual testing required"
    echo "Run: RUST_LOG=warn ./target/release/alacritty"
    exit 0
else
    echo "⚠️  Some checks failed"
    exit 1
fi
