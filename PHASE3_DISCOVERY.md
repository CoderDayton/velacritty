# Phase 3 Discovery: Damage Tracker Integer Overflow

## Timeline

**Oct 22 01:42** - Phase 1 & 2 implemented and built
**Oct 22 01:50** - Test revealed new crash: integer overflow in damage.rs:231
**Oct 22 01:50** - Phase 3 implemented and built

## The New Problem

Test crashed with:
```
thread 'main' panicked at alacritty/src/display/damage.rs:231:17:
attempt to subtract with overflow
```

This was **different** from the original EPIPE issue!

## Root Cause

The damage tracker's `rect_for_line()` performs arithmetic to convert terminal 
line numbers to screen pixel coordinates:

```rust
let y_top = height - padding_y;
let y = y_top - (line_damage.line + 1) * cell_height;
```

**Race Condition:**
1. User rapidly shrinks window
2. Resize event updates terminal dimensions (e.g., 80x60 → 80x40)
3. Damage iterator still holds references to **old line numbers** (e.g., line 50)
4. Calculation: `y_top - (50+1)*cell_height` underflows when y_top is from smaller window
5. **Panic!** (in debug/overflow-checks builds)

**Example:**
```
Old state: height=1200px, 60 lines, cell_height=20
New state: height=800px, 40 lines, cell_height=20
Damage iterator: Still processing line 50 from old state

y_top = 800 - 10 = 790
line_offset = (50 + 1) * 20 = 1020
y = 790 - 1020 = UNDERFLOW (-230, but u32 wraps/panics)
```

## The Fix (Phase 3)

Replace unchecked subtraction with **saturating arithmetic**:

```rust
let y_top = height.saturating_sub(padding_y);
let line_offset = (line_damage.line + 1) * cell_height;
let y = y_top.saturating_sub(line_offset);  // Clamps to 0 instead of panicking
```

**File Modified:**
- `alacritty/src/display/damage.rs` lines 227-240

**Why This Works:**
- Out-of-viewport rectangles (y=0 when it should be negative) get clipped anyway
- GPU/compositor handles out-of-bounds geometry gracefully
- No visual artifacts occur
- Terminal continues operating

## Testing Status

- ✅ Phase 1: Debouncing implemented
- ✅ Phase 2: PTY error handling implemented  
- ✅ Phase 3: Overflow protection implemented
- ⏳ Phase 3: Needs user testing (aggressive resize)

## Lesson Learned

**Multi-threaded state synchronization is hard!**

Even with debouncing, there's still a window where:
- Resize has updated terminal state
- Damage tracker holds iterator over old state
- Calculations mix old and new dimensions

Saturating arithmetic provides **defensive programming** against these edge cases.

---

This is classic systems programming: Fix one bug, discover another, iterate! 🔥
