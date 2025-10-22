#!/bin/bash
# Test auto-scroll toggle feature
# Usage: Run this in one terminal, then manually test in the Alacritty window

echo "=== Auto-Scroll Toggle Test ==="
echo ""
echo "This script will:"
echo "1. Launch Alacritty with RUST_LOG=warn (to see toggle messages)"
echo "2. Generate continuous output"
echo ""
echo "Manual Test Steps:"
echo "  a) Scroll up with PageUp (or mouse wheel)"
echo "  b) Type some characters (e.g., 'hello')"
echo "  c) Observe: viewport SHOULD snap back to bottom (default behavior)"
echo "  d) Scroll up again"
echo "  e) Press Shift+Ctrl+A (toggle auto-scroll OFF)"
echo "  f) Type some characters again"
echo "  g) Observe: viewport SHOULD stay where it is (toggle worked!)"
echo "  h) Press Shift+Ctrl+A again (toggle ON)"
echo "  i) Type characters"
echo "  j) Observe: viewport snaps back to bottom again"
echo ""
echo "Press Enter to launch test..."
read

# Launch Alacritty with logging enabled and continuous output
RUST_LOG=warn ./target/debug/alacritty -e bash -c '
echo "Generating continuous output...";
echo "Scroll up and type something to test auto-scroll behavior";
echo "Press Shift+Ctrl+A to toggle auto-scroll";
echo "";
for i in {1..100}; do
    echo "Line $i - $(date +%H:%M:%S)";
    sleep 0.5;
done;
echo "Test complete. Terminal will stay open.";
bash;  # Keep terminal open
'
