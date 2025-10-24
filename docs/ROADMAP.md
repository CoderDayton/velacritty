# Velacritty Development Roadmap

## Document Metadata

- **Project**: Velacritty (Fork of Alacritty)
- **Purpose**: Enhanced visual features while maintaining Alacritty's performance
- **Repository**: https://github.com/CoderDayton/velacritty
- **Upstream**: https://github.com/alacritty/alacritty
- **Status**: Foundation Complete, Feature Development Ready
- **Last Updated**: 2025-10-22

---

## 1. Project Vision

**Velacritty** is an independent fork of Alacritty that extends the terminal with enhanced visual capabilities while preserving the performance and reliability that makes Alacritty exceptional.

### 1.1 Core Philosophy

```
速度 (Speed)    → Alacritty's performance foundation
美学 (Aesthetics) → Enhanced visual features
和谐 (Harmony)   → Balance between performance and beauty
```

**Design Principles**:
- **Performance First**: Visual enhancements must not degrade input latency or rendering performance
- **Configuration Optional**: All visual features configurable/disablable
- **Cross-Platform**: Features work consistently on Linux/macOS/Windows
- **Upstream Compatible**: Can selectively merge Alacritty upstream changes

---

## 2. Current Status (As of 2025-10-22)

### 2.1 Foundation Complete ✅

| Component | Status | Notes |
|-----------|--------|-------|
| **CI Pipeline** | ✅ Passing | Linux, macOS, Windows all green |
| **Test Coverage** | ✅ 87 tests | Core suite + platform-specific tests |
| **Clippy Compliance** | ✅ Clean | `#![deny(clippy::all)]` enforced |
| **Branding** | ✅ Partial | User-facing strings updated, repo renamed |
| **Documentation** | ✅ SDD | Auto-scroll feature documented |

### 2.2 Technical Achievements

**Session Commits** (2025-10-22):
1. `1b2e1e88` - Document Q2/Q3 test infrastructure in SDD
2. `ff166b6c` - Rebrand user-facing strings to "Velacritty"
3. `b6586406` - Fix Linux CI dependencies (fontconfig, libxcb)
4. `3eedd275` - Fix workspace test command semantics
5. `3ee73479` - Resolve Clippy lints (bool_assert, div_ceil)

**Lessons Learned**:
- Cargo workspace feature flags require package-level context
- System dependencies (C libraries) must be explicit in CI
- Clippy evolution requires continuous code modernization

---

## 3. Development Options

### Option A: Visual Enhancements 🎨

**Priority**: High
**Impact**: High (differentiates Velacritty from Alacritty)
**Complexity**: Medium-High (requires renderer knowledge)

#### A.1 Gradient Title Bars

**Description**: GPU-accelerated gradient rendering for window title bars

**Technical Approach**:
- Custom renderer for window decorations
- Shader-based gradient computation
- Configurable color stops (2-N colors)

**Configuration Example**:
```toml
[window.decorations]
gradient_enabled = true
gradient_colors = ["#667eea", "#764ba2"]  # Top-to-bottom
gradient_angle = 90  # Degrees (0 = horizontal, 90 = vertical)
```

**Implementation Files**:
- `alacritty/src/display/window.rs` - Window decoration logic
- `alacritty/src/renderer/mod.rs` - Renderer integration
- `alacritty/res/gradient.v.glsl` / `gradient.f.glsl` - Shader code

**Performance Constraints**:
- Must render in <1ms (target: 144Hz support)
- Single draw call per frame
- No CPU-side gradient computation

**Estimated Effort**: 2-3 days (shader development + integration + testing)

---

#### A.2 Glassmorphism / Blur Effects

**Description**: Platform-native blur for terminal background

**Platform-Specific APIs**:
```rust
// macOS: NSVisualEffectView
#[cfg(target_os = "macos")]
fn enable_blur(window: &Window) {
    // Objective-C bridge to NSVisualEffectView
}

// Windows: Acrylic / Mica materials
#[cfg(target_os = "windows")]
fn enable_blur(window: &Window) {
    // DWM (Desktop Window Manager) API
}

// Linux: Compositor blur hints
#[cfg(target_os = "linux")]
fn enable_blur(window: &Window) {
    // X11: _NET_WM_BLUR_BEHIND property
    // Wayland: blur protocol (compositor-dependent)
}
```

**Configuration Example**:
```toml
[window.blur]
enabled = true
radius = 20  # Blur radius in pixels
opacity = 0.85  # Background opacity (0.0-1.0)
```

**Challenges**:
- **Linux**: Compositor-dependent (works on KWin, Picom; not GNOME)
- **Performance**: Blur is GPU-intensive; may impact low-end hardware
- **Text Contrast**: Requires careful color selection to maintain readability

**Estimated Effort**: 4-5 days (platform-specific APIs + fallback handling)

---

#### A.3 Animated Borders

**Description**: Shader-based border animations (breathing, pulsing, rainbow)

**Technical Approach**:
```rust
// Border shader with time uniform
uniform float u_time;
uniform vec4 u_base_color;
uniform int u_animation_mode;  // 0=static, 1=breathing, 2=rainbow

void main() {
    if (u_animation_mode == 1) {
        // Breathing: sine wave opacity modulation
        float alpha = 0.5 + 0.5 * sin(u_time * 2.0);
        gl_FragColor = vec4(u_base_color.rgb, alpha);
    } else if (u_animation_mode == 2) {
        // Rainbow: HSV color cycling
        float hue = mod(u_time * 0.1, 1.0);
        gl_FragColor = hsv_to_rgb(hue, 1.0, 1.0);
    }
}
```

**Configuration Example**:
```toml
[window.border]
width = 2  # Border width in pixels
animation = "breathing"  # Options: "static", "breathing", "rainbow", "pulse"
color = "#667eea"  # Base color (used in static/breathing modes)
speed = 1.0  # Animation speed multiplier
```

**Performance Target**:
- 60 FPS minimum (16.67ms frame budget)
- Border rendering: <0.5ms per frame
- Use instanced rendering (single draw call)

**Estimated Effort**: 2 days (shader + config integration)

---

#### A.4 Enhanced Padding / Spacing

**Description**: Per-side padding configuration for flexible layouts

**Current Limitation**:
```toml
[window.padding]
x = 5  # Applied to left AND right
y = 5  # Applied to top AND bottom
```

**Proposed Enhancement**:
```toml
[window.padding]
# Option 1: Explicit per-side
top = 10
right = 5
bottom = 10
left = 5

# Option 2: CSS-style shorthand
padding = [10, 5, 10, 5]  # [top, right, bottom, left]
```

**Implementation**:
- Modify `alacritty/src/config/window.rs` padding struct
- Update `alacritty/src/display/content.rs` viewport calculation
- Maintain backward compatibility (detect old vs new config)

**Estimated Effort**: 1 day (config parsing + rendering adjustments)

---

### Option B: Performance Tuning ⚡

**Priority**: Medium
**Impact**: Medium (maintains Alacritty's performance edge)
**Complexity**: High (requires profiling expertise)

#### B.1 GPU Batch Submission Analysis

**Goal**: Minimize draw calls per frame

**Investigation Steps**:
1. **Instrument Renderer**:
   ```rust
   // Add to alacritty/src/renderer/mod.rs
   pub struct RenderStats {
       draw_calls: usize,
       vertices_submitted: usize,
       state_changes: usize,
   }
   ```

2. **Profile with Tracy**:
   - Integrate Tracy profiler (frame-by-frame GPU analysis)
   - Identify redundant state changes
   - Measure batch efficiency

3. **Optimization Targets**:
   - Current baseline: ??? draw calls/frame (measure first)
   - Target: <5 draw calls/frame for typical terminal content

**Estimated Effort**: 3-4 days (profiling + optimization + verification)

---

#### B.2 Text Rendering Cache Efficiency

**Goal**: Maximize glyph atlas cache hit rate

**Metrics to Measure**:
```rust
pub struct CacheStats {
    hits: u64,
    misses: u64,
    evictions: u64,
    atlas_utilization: f32,  // % of atlas texture used
}
```

**Analysis Questions**:
1. What is current cache hit rate? (Target: >95%)
2. How often are glyphs evicted? (Target: <1% per frame)
3. Is atlas size optimal? (Trade-off: memory vs. cache misses)

**Potential Optimizations**:
- Increase atlas size for common fonts
- Pre-populate cache with ASCII characters
- Smarter eviction policy (LRU → LFU for code/logs)

**Estimated Effort**: 2-3 days (instrumentation + analysis + tuning)

---

#### B.3 Damage Tracking Verification

**Goal**: Confirm only changed regions are redrawn

**Current Implementation** (verify exists):
- `alacritty/src/display/damage.rs` exists (✅ damage tracking present)

**Verification Steps**:
1. Add debug visualization mode (highlight damaged regions)
2. Test scenarios:
   - Cursor blinking (should only damage cursor cell)
   - Single line output (should only damage that line)
   - Full screen TUI (verify full repaint when needed)

3. Measure:
   - % of frames with full repaint vs. partial
   - GPU time for full vs. partial redraws

**Estimated Effort**: 1-2 days (verification + documentation)

---

### Option C: Fork Maintenance 🔧

**Priority**: High (enables long-term sustainability)
**Impact**: High (automation reduces manual overhead)
**Complexity**: Low-Medium (GitHub Actions workflow development)

#### C.1 Automatic Upstream Sync

**Goal**: Track `alacritty/alacritty` main branch and create sync PRs

**Implementation**:
```yaml
# .github/workflows/upstream-sync.yml
name: Sync Upstream Alacritty

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:      # Manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for merge
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Configure Git
        run: |
          git config user.name "Velacritty Bot"
          git config user.email "bot@velacritty.dev"

      - name: Add upstream remote
        run: |
          git remote add upstream https://github.com/alacritty/alacritty.git || true
          git fetch upstream main

      - name: Check for divergence
        id: check
        run: |
          BEHIND=$(git rev-list --count HEAD..upstream/main)
          echo "commits_behind=$BEHIND" >> $GITHUB_OUTPUT

      - name: Create sync branch
        if: steps.check.outputs.commits_behind > 0
        run: |
          BRANCH="sync-upstream-$(date +%Y%m%d)"
          git checkout -b "$BRANCH"
          git merge upstream/main --no-edit || echo "CONFLICT=true" >> $GITHUB_ENV

      - name: Create PR
        if: steps.check.outputs.commits_behind > 0
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          CONFLICT_TAG=""
          if [ "$CONFLICT" = "true" ]; then
            CONFLICT_TAG="⚠️ CONFLICTS - Manual resolution required"
          fi

          gh pr create \
            --title "Sync upstream Alacritty changes ($(date +%Y-%m-%d)) $CONFLICT_TAG" \
            --body "Automated sync from alacritty/alacritty main branch.

            **Commits behind**: ${{ steps.check.outputs.commits_behind }}
            **Upstream URL**: https://github.com/alacritty/alacritty

            Review changes carefully to ensure no Velacritty-specific features are overwritten."
```

**Estimated Effort**: 1 day (workflow development + testing)

---

#### C.2 Release Pipeline

**Goal**: Build platform-specific binaries on release tags

**Implementation**:
```yaml
# .github/workflows/release.yml (extend existing)
name: Release

on:
  push:
    tags:
      - 'v*'  # Trigger on version tags (e.g., v0.17.0)

jobs:
  build-release:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: x86_64-unknown-linux-gnu
            artifact_name: velacritty-linux-x86_64
          - os: macos-latest
            target: x86_64-apple-darwin
            artifact_name: velacritty-macos-x86_64
          - os: macos-latest
            target: aarch64-apple-darwin
            artifact_name: velacritty-macos-aarch64
          - os: windows-latest
            target: x86_64-pc-windows-msvc
            artifact_name: velacritty-windows-x86_64.exe

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Install Rust target
        run: rustup target add ${{ matrix.target }}

      - name: Build release binary
        run: cargo build --release --target ${{ matrix.target }}

      - name: Package binary
        run: |
          cp target/${{ matrix.target }}/release/alacritty ${{ matrix.artifact_name }}

      - name: Upload to release
        uses: softprops/action-gh-release@v1
        with:
          files: ${{ matrix.artifact_name }}
          generate_release_notes: true
```

**Auto-Changelog Generation**:
```yaml
- name: Generate changelog
  run: |
    git log $(git describe --tags --abbrev=0 HEAD^)..HEAD \
      --pretty=format:"- %s (%h)" \
      --no-merges > CHANGELOG.txt
```

**Estimated Effort**: 1-2 days (workflow + testing across platforms)

---

#### C.3 Divergence Documentation

**Goal**: Track which files differ from upstream Alacritty

**Implementation**:
```bash
#!/bin/bash
# scripts/track-divergence.sh

UPSTREAM_REMOTE="https://github.com/alacritty/alacritty.git"
UPSTREAM_BRANCH="main"

echo "# Velacritty Divergence Report"
echo "Generated: $(date)"
echo ""

# Fetch upstream
git remote add upstream-check $UPSTREAM_REMOTE 2>/dev/null || true
git fetch upstream-check $UPSTREAM_BRANCH

# Compare files
echo "## Modified Files"
git diff --name-only upstream-check/$UPSTREAM_BRANCH...HEAD | while read file; do
    echo "- \`$file\`"

    # Show commit that last modified this file
    LAST_COMMIT=$(git log -1 --format="%h - %s" -- "$file")
    echo "  - Last change: $LAST_COMMIT"
done

echo ""
echo "## New Files (not in upstream)"
git diff --name-only --diff-filter=A upstream-check/$UPSTREAM_BRANCH...HEAD

echo ""
echo "## Deleted Files (removed from upstream)"
git diff --name-only --diff-filter=D upstream-check/$UPSTREAM_BRANCH...HEAD
```

**Scheduled Report**:
```yaml
# .github/workflows/divergence-report.yml
on:
  schedule:
    - cron: '0 0 1 * *'  # Monthly
  workflow_dispatch:

jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate report
        run: bash scripts/track-divergence.sh > divergence-report.md

      - name: Create issue
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh issue create \
            --title "Monthly Divergence Report ($(date +%B\ %Y))" \
            --body-file divergence-report.md \
            --label "maintenance"
```

**Estimated Effort**: 1 day (script + automation)

---

### Option D: Community Building 👥

**Priority**: Medium
**Impact**: High (attracts contributors and users)
**Complexity**: Low (documentation and outreach)

#### D.1 README Rewrite

**Goal**: Clear project identity and installation instructions

**Structure**:
```markdown
# Velacritty

> Alacritty with enhanced visual features

[![CI Status](badge)](link)
[![Release](badge)](link)

## Why Velacritty?

**Velacritty** extends Alacritty with visual enhancements while preserving its legendary performance.

| Feature | Alacritty | Velacritty |
|---------|-----------|------------|
| GPU-accelerated rendering | ✅ | ✅ |
| Cross-platform support | ✅ | ✅ |
| Sub-millisecond input latency | ✅ | ✅ |
| Gradient title bars | ❌ | ✅ |
| Glassmorphism blur | ❌ | ✅ |
| Animated borders | ❌ | ✅ |

## Installation

[Platform-specific instructions]

## Configuration

[Example velacritty.toml with new features]

## Screenshots

[Visual showcase]

## Relationship to Alacritty

Velacritty is an independent fork that:
- Maintains compatibility with upstream Alacritty configurations
- Selectively merges upstream bug fixes and performance improvements
- Adds opt-in visual features without compromising core performance

## Contributing

[Guidelines]
```

**Estimated Effort**: 2-3 hours (writing + screenshots)

---

#### D.2 Screenshot Gallery

**Goal**: Showcase visual enhancements

**Content**:
1. **Default Alacritty vs. Velacritty comparison**
   - Side-by-side screenshots
   - Highlight visual differences

2. **Feature Demonstrations**:
   - Gradient title bars (multiple color schemes)
   - Glassmorphism blur (various opacity levels)
   - Animated borders (GIF/video capture)
   - Custom padding configurations

3. **Theme Showcase**:
   - Popular color schemes (Dracula, Nord, Gruvbox)
   - Light vs. dark mode
   - High-contrast accessibility themes

**Tools**:
- `scrot` / `gnome-screenshot` (Linux)
- `screencapture` (macOS)
- `ScreenToGif` (Windows - for animations)

**Estimated Effort**: 1 day (capturing + organizing)

---

#### D.3 Community Spaces

**Options**:

1. **GitHub Discussions** (Recommended)
   - Built into GitHub (no extra infrastructure)
   - Categories: Feature Requests, Show and Tell, Q&A, Development

2. **Discord Server**
   - Real-time chat
   - Channels: #general, #development, #showcase, #support

3. **Matrix Space**
   - Open protocol (alternative to Discord)
   - Bridges to IRC/Discord

**Initial Setup**:
- Enable GitHub Discussions
- Pin welcome thread explaining project goals
- Create issue templates (bug report, feature request, config help)

**Estimated Effort**: 2-3 hours (setup + initial content)

---

## 4. Recommended Priority Order

### Phase 1: Identity & Infrastructure (Week 1)
**Goal**: Establish Velacritty as distinct project with sustainable workflows

1. ✅ **Repo Rename** (Current task - in progress)
2. **README Rewrite** (Option D.1) - 2-3 hours
3. **Upstream Sync Automation** (Option C.1) - 1 day
4. **Release Pipeline** (Option C.2) - 1-2 days

**Rationale**: Foundation must be solid before feature development. Automation prevents technical debt.

---

### Phase 2: First Visual Feature (Week 2)
**Goal**: Ship one differentiating visual feature

**Recommended**: **Animated Borders** (Option A.3)
- Lowest complexity among visual features
- High visual impact (immediately noticeable)
- Doesn't require platform-specific APIs
- Good introduction to renderer architecture

**Deliverables**:
- Shader implementation
- Configuration options
- Documentation with examples
- Screenshot/GIF for README

---

### Phase 3: Performance Baseline (Week 3)
**Goal**: Establish performance metrics before adding complex features

1. **GPU Batch Analysis** (Option B.1) - 3-4 days
2. **Cache Efficiency** (Option B.2) - 2-3 days

**Rationale**: Measure first, optimize later. Establishes performance budget for future features.

---

### Phase 4: Advanced Visual Features (Weeks 4-6)
**Goal**: Implement high-impact visual enhancements

1. **Gradient Title Bars** (Option A.1) - 2-3 days
2. **Glassmorphism Blur** (Option A.2) - 4-5 days
3. **Enhanced Padding** (Option A.4) - 1 day

**Rationale**: By now, renderer is well-understood from Phase 2. Performance budget is known from Phase 3.

---

### Phase 5: Community Launch (Week 7)
**Goal**: Public announcement and community onboarding

1. **Screenshot Gallery** (Option D.2) - 1 day
2. **Enable GitHub Discussions** (Option D.3) - 2-3 hours
3. **Announcement Posts**:
   - Reddit: r/unixporn, r/rust, r/terminal
   - Hacker News: "Show HN: Velacritty - Alacritty with enhanced visuals"
   - Twitter/Mastodon

---

## 5. Long-Term Vision (3-6 months)

### 5.1 Unique Features (Not in Alacritty)

1. **Plugin System**
   - Lua/WASM scripting for custom visual effects
   - Community-contributed shaders

2. **Live Configuration Reload**
   - Hot-reload colors/themes without restart
   - WebSocket-based remote configuration

3. **Terminal Themes Marketplace**
   - Community-curated theme repository
   - One-command theme installation

### 5.2 Upstream Contributions

**Philosophy**: Give back to Alacritty when possible

**Potential Contributions**:
- Bug fixes discovered during Velacritty development
- Performance optimizations (if generally applicable)
- Platform-specific fixes (especially macOS/Windows)

**Process**:
1. Develop fix in Velacritty first
2. Test thoroughly across platforms
3. Submit PR to `alacritty/alacritty` with clear description
4. Credit Velacritty project in commit message

---

## 6. Technical Constraints

### 6.1 Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Input Latency** | <5ms | Time from keystroke to screen update |
| **Frame Time** | <6.9ms | 144 FPS support |
| **Startup Time** | <100ms | Time to first frame |
| **Memory Usage** | <50MB | Baseline without scrollback |

**Visual features must not degrade these metrics by >5%.**

### 6.2 Compatibility Requirements

1. **Configuration**: Must accept Alacritty's `alacritty.toml` format
2. **Terminfo**: Continue using `alacritty` terminfo database
3. **Escape Sequences**: Full compatibility with Alacritty's escape sequence support

### 6.3 Platform Support

| Platform | Support Level | Notes |
|----------|---------------|-------|
| **Linux (X11)** | ✅ Tier 1 | Primary development platform |
| **Linux (Wayland)** | ✅ Tier 1 | Compositor-dependent for blur |
| **macOS (Intel)** | ✅ Tier 1 | Native blur via NSVisualEffectView |
| **macOS (Apple Silicon)** | ✅ Tier 1 | CI tests both architectures |
| **Windows 10/11** | ✅ Tier 1 | Acrylic/Mica materials for blur |
| **FreeBSD** | ⚠️ Tier 2 | Community-maintained |

---

## 7. Resources & References

### 7.1 Alacritty Documentation
- **Main Repo**: https://github.com/alacritty/alacritty
- **Architecture**: https://github.com/alacritty/alacritty/blob/master/docs/SDD.md
- **Renderer**: `alacritty/src/renderer/` - OpenGL rendering pipeline

### 7.2 Graphics Programming
- **Learn OpenGL**: https://learnopengl.com/
- **Book of Shaders**: https://thebookofshaders.com/
- **Tracy Profiler**: https://github.com/wolfpld/tracy

### 7.3 Platform-Specific APIs

**macOS**:
- NSVisualEffectView: https://developer.apple.com/documentation/appkit/nsvisualeffectview

**Windows**:
- Acrylic Material: https://docs.microsoft.com/en-us/windows/apps/design/style/acrylic
- DWM API: https://docs.microsoft.com/en-us/windows/win32/dwm/dwm-overview

**Linux**:
- X11 blur hints: https://specifications.freedesktop.org/wm-spec/wm-spec-latest.html
- KWin blur: https://invent.kde.org/plasma/kwin/-/tree/master/src/plugins/blur

---

## 8. Decision Log

### 2025-10-22: Repository Rename
- **Decision**: Rename GitHub repo from "alacritty" to "velacritty"
- **Rationale**: Clear project identity separation from upstream
- **Impact**: Requires updating git remotes, documentation, CI badges
- **Status**: In progress

### 2025-10-22: Feature Prioritization
- **Decision**: Implement Animated Borders (A.3) as first visual feature
- **Rationale**: Lowest complexity, high impact, good learning opportunity
- **Alternatives Considered**: Gradient title bars (higher complexity), blur (platform-specific challenges)

---

## 9. Glossary

- **Upstream**: The original Alacritty repository (`alacritty/alacritty`)
- **Divergence**: Files/features that differ from upstream
- **MSRV**: Minimum Supported Rust Version (currently 1.73+)
- **CI**: Continuous Integration (GitHub Actions workflows)
- **SDD**: System Design Document (this and related documentation)

---

## Appendix: Quick Reference Commands

```bash
# Update from upstream (manual)
git remote add upstream https://github.com/alacritty/alacritty.git
git fetch upstream main
git merge upstream/main

# Run all tests
cargo test

# Run Clippy (strict linting)
cargo clippy --all-targets

# Build release binary
cargo build --release

# Profile with flamegraph
cargo install flamegraph
sudo flamegraph -- target/release/alacritty

# Generate divergence report
bash scripts/track-divergence.sh
```

---

**Document Status**: ✅ Complete
**Next Review**: After Phase 1 completion
