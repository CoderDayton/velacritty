# Auto-Scroll Feature Test Results

**Date**: 2025-10-22  
**Branch**: feat/visual-improvements  
**Commit**: 902ccbf9 (+ uncommitted changes)  

---

## Implementation Status ✅

### Code Review
- [x] `Action::ToggleAutoScroll` enum variant (bindings.rs)
- [x] `auto_scroll_enabled: bool` field in Display struct (display/mod.rs:534)
- [x] Toggle handler in input/mod.rs:402-407
- [x] Snap-back logic in event.rs:1371-1374
- [x] Config initialization from `config.scrolling.auto_scroll` (display/mod.rs:534)
- [x] Keybinding: Shift+Ctrl+A → ToggleAutoScroll (bindings.rs)
- [x] Debug logging in toggle handler (input/mod.rs:405)
- [x] Debug logging in snap-back logic (event.rs:1365-1369, 1372)

### Call Chain ✅
```
User types key
  → input/keyboard.rs:on_terminal_input_start()
    → event.rs:on_terminal_input_start()
      → Checks: auto_scroll_enabled && display_offset != 0
        → If true: scroll(Scroll::Bottom)
```

---

## Expected Behavior (Clarified)

### ❌ INCORRECT Understanding (from docs)
> "Controls whether viewport follows new terminal output"

### ✅ CORRECT Understanding
> "Controls snap-back-to-bottom when typing WHILE scrolled up"

### Detailed Behavior Matrix

| State | Action | Result |
|-------|--------|--------|
| **auto_scroll=true** (default) | New output arrives | Viewport follows IF at bottom, locks IF scrolled up |
| | User scrolls up | Viewport locks at historical content |
| | **User types while scrolled up** | **Viewport SNAPS to bottom** ⬅️ THIS IS THE FEATURE |
| **auto_scroll=false** (disabled) | New output arrives | Viewport follows IF at bottom, locks IF scrolled up |
| | User scrolls up | Viewport locks at historical content |
| | **User types while scrolled up** | **Viewport STAYS locked** ⬅️ THIS IS THE DIFFERENCE |

---

## Test Procedure (Manual)

### Test 1: Default Behavior (auto_scroll=true)
```bash
RUST_LOG=debug ./target/release/alacritty
```

**Steps:**
1. Generate output: `yes | head -50`
2. Scroll up with PageUp (about 10 lines)
3. Verify display_offset != 0 (viewport is scrolled)
4. Type any character (e.g., 'h')
5. **Expected**: Viewport jumps to bottom
6. **Log should show**: `auto_scroll_enabled=true, display_offset=X`

### Test 2: Toggled Behavior (Shift+Ctrl+A)
```bash
RUST_LOG=warn ./target/release/alacritty
```

**Steps:**
1. Generate output: `yes | head -50`
2. Scroll up with PageUp
3. Press **Shift+Ctrl+A**
4. **Expected log**: `Toggled auto_scroll: true -> false`
5. Type any character (e.g., 'h')
6. **Expected**: Viewport STAYS scrolled (does NOT snap)
7. Press **Shift+Ctrl+A** again
8. **Expected log**: `Toggled auto_scroll: false -> true`
9. Type any character
10. **Expected**: Viewport snaps to bottom (restored)

### Test 3: Config Option (-o flag)
```bash
./target/release/alacritty -o scrolling.auto_scroll=false
```

**Steps:**
1. Generate output: `yes | head -50`
2. Scroll up with PageUp
3. Type any character
4. **Expected**: Viewport STAYS scrolled (initialized as disabled)

---

## Potential Issues to Investigate

### Issue 1: Misconception of Feature Behavior
**Symptom**: User reports "no observable difference"

**Root Cause Hypothesis**: User may be expecting:
- Auto-scroll to control whether viewport follows NEW OUTPUT
- But feature ONLY controls snap-back when TYPING while scrolled

**Verification Needed**: Confirm user was testing:
- ❌ Watching new output appear while scrolled up?
- ✅ Typing characters while manually scrolled up?

### Issue 2: Display Offset Not Detected
**Symptom**: `display_offset` remains 0 even after scrolling

**Possible Causes**:
- Mouse wheel scrolling not updating grid state
- WSL2-specific scrolling behavior
- Wayland compositor interference

**Debug Command**:
```bash
RUST_LOG=alacritty=debug ./target/release/alacritty 2>&1 | grep display_offset
```

### Issue 3: Input Not Triggering Handler
**Symptom**: `on_terminal_input_start` never called

**Possible Causes**:
- Modifier keys being used (on_terminal_input_start skipped)
- Paste mode vs typing mode difference
- IME (Input Method Editor) interference

**Debug**: Add log at top of `on_terminal_input_start`

### Issue 4: Config Not Loading
**Symptom**: `-o scrolling.auto_scroll=false` has no effect

**Possible Causes**:
- Config parsing fails silently
- Field name mismatch in config struct
- Override not applied before Display initialization

**Verification**:
```bash
rg "scrolling.*auto_scroll" alacritty/src/config/
```

---

## Next Steps

### Immediate Actions
1. **Fix Documentation** (docs/SDD.md lines 1467-1571)
   - Correct behavior description
   - Update test procedures
   - Clarify "snap-back" vs "follow output"

2. **User Validation** - Need confirmation:
   - [ ] Were you typing characters while scrolled up?
   - [ ] Or just watching output appear while scrolled?
   - [ ] Did you see the "Toggled auto_scroll" log message?

3. **Enhanced Debugging** (if issue persists):
   ```rust
   // Add to event.rs:1364
   log::warn!("🔍 on_terminal_input_start called: enabled={}, offset={}", 
       self.display.auto_scroll_enabled, display_offset);
   
   // Add to display/mod.rs:534
   log::warn!("🔧 Display initialized with auto_scroll_enabled={}", 
       config.scrolling.auto_scroll);
   ```

### If Issue Confirmed as Real Bug
- Add visual feedback (message bar): "Auto-scroll: ON/OFF"
- Add integration test for snap-back behavior
- Test on multiple platforms (X11, Wayland, macOS)
- Verify WSL2-specific behavior

---

## Technical Debt

### Documentation Fixes Required
**File**: `docs/SDD.md`

**Lines to Correct**:
```diff
- Line 1467-1471: Remove TUI vs shell distinction (incorrect motivation)
- Line 1487: "on terminal output" → "on terminal INPUT (typing)"
- Line 1499: "on terminal output" → "on terminal INPUT (typing)"  
- Line 1571-1572: Correct test description
```

**Correct Description**:
```markdown
**Auto-Scroll Feature**: Controls viewport snap-back when typing while scrolled up.
- **Enabled** (default): Typing while scrolled → viewport jumps to bottom
- **Disabled**: Typing while scrolled → viewport remains locked
- **Does NOT affect**: Following new output (always follows if at bottom)
```

---

## Build Information

```
Rust: 1.82.0 (stable)
Target: x86_64-unknown-linux-gnu
Profile: release [optimized + debuginfo]
Build time: 28.37s
Binary: ./target/release/alacritty
```

## Log Levels for Testing

```bash
# Minimal (toggle messages only)
RUST_LOG=warn ./target/release/alacritty

# Detailed (snap-back logic)
RUST_LOG=debug ./target/release/alacritty

# Full trace (all events)
RUST_LOG=trace ./target/release/alacritty 2>&1 | tee /tmp/alacritty.log
```
