# Migration Guide: Alacritty → Velacritty

This guide helps users transition from Alacritty to Velacritty, documenting breaking changes and providing migration strategies.

---

## Overview

Velacritty is designed to be **mostly compatible** with Alacritty, with minimal changes required for most users. However, some default behaviors have changed to reflect Velacritty's identity as a fork.

---

## Breaking Changes

### 1. Window Title and Class (v0.17.0-dev+)

**What Changed:**
- **Default window title:** `"Alacritty"` → `"Velacritty"`
- **Default window class:** `Alacritty` → `Velacritty`

**Who Is Affected:**
- Users with **window manager rules** (i3, sway, Hyprland, etc.) matching `class="Alacritty"`
- Users with **shell scripts** checking window titles for "Alacritty"
- Users with **desktop automation** tools referencing Alacritty window names

**How to Migrate:**

#### Option A: Update Window Manager Rules (Recommended)

**i3 / sway:**
```diff
# Before:
- for_window [class="Alacritty"] opacity 0.95
- for_window [app_id="Alacritty"] opacity 0.95

# After:
+ for_window [class="Velacritty"] opacity 0.95
+ for_window [app_id="Velacritty"] opacity 0.95
```

**Hyprland:**
```diff
# Before:
- windowrule = opacity 0.95,^(Alacritty)$

# After:
+ windowrule = opacity 0.95,^(Velacritty)$
```

**Awesome WM:**
```diff
-- Before:
- awful.rules.rules = {
-   { rule = { class = "Alacritty" },
-     properties = { opacity = 0.95 } },
- }

-- After:
+ awful.rules.rules = {
+   { rule = { class = "Velacritty" },
+     properties = { opacity = 0.95 } },
+ }
```

**bspwm:**
```diff
# Before:
- bspc rule -a Alacritty state=floating

# After:
+ bspc rule -a Velacritty state=floating
```

#### Option B: Keep "Alacritty" Branding (Workaround)

If you prefer to keep the original "Alacritty" branding, add this to your `~/.config/alacritty/alacritty.toml`:

```toml
[window]
title = "Alacritty"

[window.class]
general = "Alacritty"
instance = "Alacritty"
```

This will restore the original window title and class names.

#### Option C: Use Command-Line Flags

Override defaults on a per-launch basis:

```bash
# Keep Alacritty branding for this session
velacritty --title "Alacritty" --class Alacritty

# Or use custom branding
velacritty --title "MyTerminal" --class MyTerminal
```

---

## Non-Breaking Changes

### Configuration File Location

✅ **No changes required!** Velacritty reads from the same locations as Alacritty:

**Linux/BSD/macOS:**
1. `$XDG_CONFIG_HOME/alacritty/alacritty.toml`
2. `$XDG_CONFIG_HOME/alacritty.toml`
3. `$HOME/.config/alacritty/alacritty.toml`
4. `$HOME/.alacritty.toml`
5. `/etc/alacritty/alacritty.toml`

**Windows:**
- `%APPDATA%\alacritty\alacritty.toml`

Your existing Alacritty config will be automatically detected and used.

> **Note:** Future versions may support `velacritty` config paths while maintaining backward compatibility.

### Binary Name

✅ **No changes required!** The binary is still named `alacritty` for backward compatibility:

```bash
# Both work the same way:
alacritty --help
velacritty --help  # If you create a symlink
```

This ensures compatibility with:
- Terminal launchers (Rofi, dmenu, Albert, etc.)
- Shell scripts that invoke `alacritty`
- Desktop entries and application launchers
- Build systems and automation tools

### Configuration Syntax

✅ **No changes required!** All Alacritty config options work identically in Velacritty.

---

## Verification Checklist

After migrating, verify the following:

### Window Manager Integration
- [ ] Window rules apply correctly (opacity, floating, workspace assignment)
- [ ] Window title displays as expected in taskbar/titlebar
- [ ] Window class is detected by WM (`xprop WM_CLASS` on X11)

### Shell Integration
- [ ] Terminal opens from application launchers (Rofi, dmenu, etc.)
- [ ] Shell scripts that invoke `alacritty` still work
- [ ] Desktop automation tools detect the correct window

### Configuration
- [ ] Existing config file is loaded correctly
- [ ] Custom key bindings work as expected
- [ ] Font rendering is identical to Alacritty
- [ ] Colors and theme are correctly applied

---

## Testing Window Class

### X11 (Linux/BSD)

1. Launch Velacritty
2. Get window ID:
   ```bash
   xdotool search --class velacritty
   ```
3. Check window properties:
   ```bash
   xprop WM_CLASS
   # Then click on the Velacritty window
   # Expected output: WM_CLASS(STRING) = "Velacritty", "Velacritty"
   ```

### Wayland

1. Launch Velacritty
2. Check window title in your compositor's window list
3. For Sway, verify with:
   ```bash
   swaymsg -t get_tree | grep app_id
   # Should show: "app_id": "Velacritty"
   ```

### macOS

1. Launch Velacritty
2. Window title should show "Velacritty" in the menu bar
3. Verify with AppleScript:
   ```bash
   osascript -e 'tell application "System Events" to get name of every process whose name contains "Velacritty"'
   ```

### Windows

1. Launch Velacritty
2. Check window title in taskbar
3. Verify with PowerShell:
   ```powershell
   Get-Process | Where-Object {$_.MainWindowTitle -like "*Velacritty*"}
   ```

---

## Reporting Issues

If you encounter migration issues:

1. **Check this guide first** — most issues are covered here
2. **Search existing issues:** [GitHub Issues](https://github.com/CoderDayton/alacritty/issues)
3. **Report new issues:** Include:
   - Operating system and version
   - Window manager/compositor (if applicable)
   - Your config file (sanitize sensitive data)
   - Steps to reproduce the issue

---

## Rollback to Alacritty

If you need to temporarily return to Alacritty:

1. **Keep both installed:** Velacritty and Alacritty can coexist
2. **Use absolute paths:**
   ```bash
   /usr/bin/alacritty           # Original Alacritty
   ~/velacritty/target/release/alacritty  # Velacritty binary
   ```
3. **Switch via config:** Both use the same config format, so you can test configurations with either terminal

---

## Future Breaking Changes

This document will be updated when new breaking changes are introduced. Subscribe to releases or watch the repository for notifications.

**Last Updated:** 2025-10-21 (v0.17.0-dev)
