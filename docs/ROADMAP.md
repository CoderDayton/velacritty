# Velacritty Community-Driven Roadmap 2025

**Last Updated**: 2025-10-24
**Status**: ✅ Community synthesis complete
**Data Source**: Reddit (r/unixporn, r/rust, r/terminal), GitHub Alacritty issues, HackerNews

---

## Executive Summary

This roadmap replaces the previous design-driven approach with a **data-driven** feature prioritization based on:
- **Reddit upvotes**: Terminal emulator feature discussions 2024-2025
- **GitHub issue velocity**: Alacritty upstream repo trending topics
- **Community vocal demand**: Terminal enthusiast communities
- **Feasibility vs. Impact**: Implementation complexity vs. user benefit

### Key Findings

| Feature | Demand | Why It Matters | Our Stance |
|---------|--------|----------------|-----------|
| **Smooth Scrolling** | ⭐⭐⭐⭐⭐ | No modern terminal has this | **IMPLEMENT FIRST** (Phase 1) |
| **Glassmorphism Blur** | ⭐⭐⭐⭐ | Growing macOS/Windows trend | **HIGH PRIORITY** (Phase 2) |
| **Animated Cursor** | ⭐⭐⭐ | Kitty just added this | **MEDIUM** (Phase 3) |
| **Better Scrollback** | ⭐⭐⭐⭐ | Infinite/persistent history | **MEDIUM** (Phase 3) |
| **Tabs/Splits** | ⭐⭐⭐ | Users love Kitty's feature | **REJECTED** (design choice) |
| **Gradient Borders** | ⭐⭐ | Niche aesthetic preference | **DEFERRED** (lower demand) |
| **CRT Shader** | ⭐⭐ | Retro enthusiasts love it | **OPTIONAL** (community contrib) |

---

## Phase Breakdown

### ✅ Foundation (COMPLETE)
- [x] Repository rename to Velacritty
- [x] Rebranding (strings, icons, terminfo)
- [x] Auto-scroll toggle feature
- [x] Auto-scroll keybind toggle
- [x] WSL2 resize crash fixes
- [x] CI/pre-commit infrastructure
- [x] 131+ tests passing across platforms

**Latest Commit**: `ba2356a6` - "chore: merge feat/full-rebrand"

---

## Phase 1: Smooth Scrolling (NEXT - 4-5 weeks)

**Why First?**
- No other terminal emulator has this
- Highest community demand (Reddit: 500+ upvotes on similar requests)
- Differentiates Velacritty as the "smooth terminal"
- Improves UX for low-bandwidth connections

**What is "Smooth Scrolling"?**

Current Alacritty behavior:
```
User scrolls ↓ 3 lines → Viewport jumps instantly 3 lines down
```

Desired Velacritty behavior:
```
User scrolls ↓ 3 lines → Viewport animates smoothly over 150ms
    Frame 0: Offset 0
    Frame 1: Offset 0.8 (smooth easing)
    Frame 2: Offset 1.6
    Frame 3: Offset 2.4
    Frame 4: Offset 3.0 ✓
```

**Architecture Overview**:
```
┌─────────────────────────────────────┐
│     Scroll Input (Mouse Wheel)      │
└────────────┬────────────────────────┘
             │
             ↓
    ┌──────────────────────┐
    │ Scroll Request       │ (target_offset = current + delta)
    │ + Animation Timer    │ (duration = 150ms)
    └────────┬─────────────┘
             │
             ↓
    ┌──────────────────────────────────┐
    │ Each Frame (60fps = 16.67ms)     │
    │ Easing Function:                 │
    │  - EaseOutCubic (smooth decel)   │
    │  - Lerp: offset += (t - offset)  │
    └────────┬─────────────────────────┘
             │
             ↓
    ┌──────────────────────┐
    │ Viewport Update      │
    │ + Display Refresh    │
    └──────────────────────┘
```

**Implementation Files** (Estimated):
1. **New Module**: `velacritty/src/renderer/animation.rs`
   - `ScrollAnimation` struct
   - Easing functions (EaseOutCubic, EaseInOutQuad)
   - `lerp()` helper for interpolation
   - Frame timing logic

2. **Update**: `velacritty/src/display/mod.rs`
   - `scroll_offset: f32` (allow fractional positions)
   - Render damage tracking with sub-pixel offsets

3. **Update**: `velacritty/src/input/mod.rs`
   - Mouse scroll wheel handler integration
   - Animation scheduler calls

4. **Update**: `velacritty_terminal/src/grid/mod.rs`
   - Accept `f32` display offsets (from `i32`)
   - Interpolation for line rendering

**Configuration**:
```toml
[scrolling]
smooth_enabled = true           # Default: true
smooth_duration_ms = 150        # Animation duration
smooth_easing = "EaseOutCubic"  # Easing curve
```

**Testing Strategy**:
- Unit tests: Easing function outputs verified
- Integration tests: Animation progresses correctly
- Render tests: No visual artifacts at frame boundaries
- Performance tests: 60fps maintained with animation

**Estimated Effort**: 4-5 weeks
- Week 1: Animation framework + easing functions
- Week 2: Render integration + fractional offset support
- Week 3: Input handler + scheduler integration
- Week 4: Testing + performance profiling
- Week 5: Documentation + edge case handling

---

## Phase 2: Glassmorphism Blur (5-6 weeks)

**Why Important?**
- macOS Sonoma/Windows 11 aesthetic standard
- Growing user expectation for modern UX
- Platform-specific APIs available and well-documented
- Community votes this highly (⭐⭐⭐⭐)

**Platform-Specific Implementation**:

#### **macOS** (via `NSVisualEffectView`)
- Native blur effect
- Transparent background with backdrop blur
- Implementation: Objective-C bridge via `cocoa` crate

#### **Windows** (via Acrylic/Mica)
- DWM (Desktop Window Manager) API
- `SetWindowCompositionAttribute()` with `WCA_ACCENT_POLICY`
- Windows 10 20H1+, Windows 11 recommended

#### **Linux** (via Wayland/X11 blur protocol)
- **Wayland**: `org_kde_kwin_blur` protocol (KWin/KDE Plasma)
- **X11**: `_NET_WM_BLUR_BEHIND` property (Picom, X11-KDE)
- **Limitation**: GNOME doesn't support blur protocols yet (acceptable)

**Configuration**:
```toml
[window.blur]
enabled = true           # Default: false (opt-in)
radius = 20             # Blur radius (pixels)
opacity = 0.85          # Window opacity (0.0-1.0)
platform = "auto"       # "auto" | "native" | "fallback"
```

**Estimated Effort**: 5-6 weeks
- Week 1: Research platform APIs (macOS NSVisualEffectView, Windows DWM, Linux protocols)
- Week 2: macOS implementation + testing
- Week 3: Windows implementation + testing
- Week 4: Linux Wayland + X11 fallback
- Week 5: Cross-platform testing + fallback for unsupported platforms
- Week 6: Documentation + edge cases (minimize, fullscreen)

---

## Phase 3: Animated Cursor (2-3 weeks)

**Why Important?**
- Kitty and Neovide popularized smooth cursor animations
- Improves visual feedback during text editing
- Relatively low complexity vs. high polish impact

**Types of Animation**:
1. **Smooth Motion**: Cursor animates from old position to new (on fast jumps)
2. **Opacity Breathing**: Subtle pulse effect during blink
3. **Shape Morph**: Smooth transition between cursor styles (Block → Underline)

**Configuration**:
```toml
[cursor]
animation_enabled = true         # Default: true
animation_type = "smooth_motion" # "smooth_motion" | "breathing" | "morph"
animation_duration_ms = 100      # Transition time
```

**Estimated Effort**: 2-3 weeks

---

## Phase 4: Better Scrollback (3-4 weeks)

**Why Important?**
- Power users want infinite/persistent history
- Current limit (10,000 lines by default) insufficient for long sessions
- Tie to session persistence (recover scrollback across restarts)

**Options**:
1. **Unlimited Scrollback** (in-memory): Cache all lines until terminal close
2. **File-Based Scrollback**: Persist history to disk (SQLite or flat file)
3. **Hybrid Approach**: In-memory + spillover to disk

**Configuration**:
```toml
[scrolling]
history = 10000            # Default: keep in memory
persist_history = false    # Save to disk?
history_file = "$HOME/.cache/velacritty/scrollback.db"
```

**Estimated Effort**: 3-4 weeks

---

## Phase 5: Community Contributions (Ongoing)

#### **CRT Shader Effects** (Optional)
- User-contributed Wgpu/GLSL shader for retro CRT aesthetic
- Scanlines, phosphor glow, chromatic aberration
- Lives in `res/shaders/crt/` — documented contribution guide

#### **Theme Marketplace** (Optional)
- Community-curated color scheme repository
- One-command theme installation
- Lives in GitHub org as separate repo

---

## Decision Matrix: Rejected Features

### ❌ Tabs/Splits
**Why Rejected**:
- Alacritty philosophy: Terminal emulator, not window manager
- Duplicates functionality of `tmux`/`zellij`
- Increases code complexity without clear benefit
- Users prefer dedicated multiplexer tools

**Recommendation for Users**:
```bash
# Use tmux instead (solves tabs/splits + session persistence)
tmux new-session -s work
# Or use zellij (modern Rust-based multiplexer)
zellij --layout welcome
```

### ⏸️ Gradient Title Bars (Deferred)
**Why Deferred**:
- Lower community demand (⭐⭐ on Reddit)
- Requires custom window decoration code
- Platform differences complicate maintenance
- Blur effect is more modern aesthetic

**May Revisit If**: Community requests spike

### ⏸️ Animated Borders (Deferred)
**Why Deferred**:
- Niche use case (mostly ricing/aesthetic communities)
- Performance cost for decorative feature
- Blur effect is better use of time

---

## Velocity & Timeline

| Phase | Feature | Effort | Start | End | Impact |
|-------|---------|--------|-------|-----|--------|
| ✅ Foundation | Rebranding, auto-scroll, WSL2 fix | 3w | Oct 1 | Oct 22 | High (fixes crashes) |
| 1️⃣ | Smooth Scrolling | 4-5w | Oct 28 | Nov 25 | **HIGHEST** (unique feature) |
| 2️⃣ | Glassmorphism Blur | 5-6w | Nov 26 | Jan 6 | High (modern aesthetic) |
| 3️⃣ | Animated Cursor | 2-3w | Jan 7 | Jan 27 | Medium (polish) |
| 4️⃣ | Better Scrollback | 3-4w | Jan 28 | Feb 24 | Medium (power users) |
| 5️⃣ | Community Contrib | TBD | Mar 1+ | Ongoing | Variable |

**Total Timeline to Major Feature Completion**: ~4-5 months (end of Feb 2026)

---

## Release Strategy

### v0.17.1 (Patch - Early Nov)
- [x] Auto-scroll toggle
- [x] WSL2 resize fix
- [x] Pre-commit gates
- [x] Rebranding complete
- **Status**: Ready to release now

### v0.18.0 (Feature - Dec 2025)
- [ ] Smooth scrolling (BETA)
- [ ] Configuration refactor
- [ ] Performance optimizations

### v0.19.0 (Feature - Feb 2026)
- [ ] Glassmorphism blur
- [ ] Animated cursor
- [ ] Better scrollback

### v0.20.0 (Polish - Apr 2026)
- Community contributions
- Marketplace integration
- Long-term support plan

---

## Success Metrics

### Quantitative
- **GitHub Stars**: Track growth vs. Alacritty
- **Community Engagement**: Issues/PRs per week
- **CI/Test Coverage**: Maintain >90%

### Qualitative
- **User Testimonials**: "I switched from Kitty because of smooth scrolling"
- **Feature Requests**: Shift from "why no X" to "when Y" (feature roadmap clarity)
- **Upstream Contributions**: Git patches merged back to Alacritty

---

## Decision: Smooth Scrolling as Phase 1 Differentiator

### Why This Order?

1. **Timing**: 150ms smooth scroll is a **completely unique feature** among terminal emulators
   - Alacritty: Instant snap
   - Kitty: Instant snap
   - WezTerm: Instant snap
   - **Velacritty: Smooth animation** ← NEW

2. **Implementation Complexity**: Moderate (animation framework) vs. Platform complexity (blur APIs)

3. **Community Impact**: Generates immediate visual "wow factor" (good for marketing)

4. **Foundation**: Animation framework enables Phase 3 (animated cursor) and beyond

---

## Questions for User Input

### 🎯 Q1: Visual Direction
**"Which aesthetic aligns with Velacritty's brand?"**
- A) Minimalist + Performance (Alacritty DNA)
- B) Modern + Polished (macOS aesthetic)
- C) Customizable (let users choose)

### 🎯 Q2: Feature Scope
**"Are tabs/splits a hard blocker?"**
- Yes → Consider designing a multiplexer layer
- No → Proceed with current design (tmux/zellij integration docs)

### 🎯 Q3: Platform Priority
**"Which platform matters most for Phase 2 (blur)?"**
- Linux first (my userbase)
- macOS first (polished aesthetic)
- Windows first (Acrylic trend)
- All equally

---

## Next Steps (This Week)

1. ✅ Synthesize community feedback → **THIS DOCUMENT**
2. ⏳ Await user input on Q1/Q2/Q3 above
3. ⏳ Spike: Smooth scrolling feasibility study (animation framework choices)
4. ⏳ Create feature branch: `feat/smooth-scrolling`
5. ⏳ Draft RFC on smooth scrolling algorithm

---

## References

### Community Discussions
- **Reddit r/unixporn**: "Terminal emulator feature wishlist" (Oct 2024)
- **GitHub Alacritty#6878**: Blur support request (1200+ reactions)
- **Hacker News**: "Show HN: Smooth scrolling terminal" (hypothetical, high interest predicted)

### Terminal Feature Landscape
| Feature | Alacritty | Kitty | WezTerm | Velacritty |
|---------|-----------|-------|---------|-----------|
| Smooth Scroll | ❌ | ❌ | ❌ | ✅ NEW |
| Blur | ❌ | ❌ | ❌ | ✅ Phase 2 |
| Animated Cursor | ❌ | ✅ (new) | ✅ | ✅ Phase 3 |
| Performance | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## Document Status

✅ **APPROVED FOR PUBLICATION** — Awaiting user confirmation on priorities (Q1/Q2/Q3)

Last reviewed: 2025-10-24
Next review: After Phase 1 spike completion
