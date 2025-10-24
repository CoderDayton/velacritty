# Velacritty

**A fast, cross-platform, OpenGL terminal emulator**

<p align="center">
  <em>Velacritty is a fork of Alacritty with enhanced visual features and customization</em>
</p>

---

## About Velacritty

Velacritty is a modern terminal emulator that builds upon the solid foundation of **[Alacritty](https://github.com/alacritty/alacritty)** with additional visual enhancements and user experience improvements. It comes with sensible defaults but allows for extensive [configuration](#configuration). By integrating with other applications rather than reimplementing their functionality, it provides a flexible set of features with high performance.

**Supported Platforms:** BSD, Linux, macOS, Windows

**Development Status:** Beta — actively used and continuously improved

> **⚠️ Migrating from Alacritty?** Window title/class defaults have changed to "Velacritty". If you use window manager rules, see [MIGRATION.md](MIGRATION.md) for update instructions.

---

## Attribution

> **Velacritty is a derivative work based on [Alacritty](https://github.com/alacritty/alacritty)**
> Original work Copyright © 2020 The Alacritty Project
> Licensed under Apache License 2.0 and MIT License
>
> We are deeply grateful to the Alacritty maintainers and contributors for creating the exceptional terminal emulator that serves as the foundation for this project. All core terminal emulation, rendering, and cross-platform support comes from their brilliant work.

---

## Installation

Velacritty can be built from source using Cargo (Rust's package manager).

### Requirements

- Rust 1.70.0 or higher
- At least OpenGL ES 2.0
- [Windows] ConPTY support (Windows 10 version 1809 or higher)

### Build from Source

```bash
# Clone the repository
git clone https://github.com/CoderDayton/velacritty.git velacritty
cd velacritty

# Build with cargo
cargo build --release

# The binary will be available at:
# target/release/alacritty
```

For detailed installation instructions including platform-specific requirements, see [INSTALL.md](INSTALL.md).

---

## Features

Velacritty inherits all of Alacritty's powerful features:

- **GPU-accelerated rendering** using OpenGL for buttery-smooth performance
- **Cross-platform** support (Linux, BSD, macOS, Windows)
- **Vi mode** for keyboard-driven text selection
- **Search functionality** with regex support
- **Extensive configuration** via TOML config files
- **True color support** with 24-bit colors
- **Ligature support** for programming fonts
- **Clickable URLs**
- **Configurable keybindings and mouse bindings**

### Enhanced Features in Velacritty

- **Improved scrolling behavior** with enhanced smoothness
- **Additional visual customization options**
- *(More features coming soon)*

For a complete feature overview, see [docs/features.md](./docs/features.md).

---

## Configuration

Velacritty uses the same configuration format as Alacritty. Configuration files are looked for in the following locations:

**Linux/BSD/macOS:**
1. `$XDG_CONFIG_HOME/velacritty/velacritty.toml`
2. `$XDG_CONFIG_HOME/velacritty.toml`
3. `$HOME/.config/velacritty/velacritty.toml`
4. `$HOME/.velacritty.toml`
5. `/etc/velacritty/velacritty.toml`

**Windows:**
* `%APPDATA%\velacritty\velacritty.toml`

> **Note:** Velacritty uses its own dedicated configuration paths. To migrate from Alacritty, copy your config to the new location: `cp ~/.config/alacritty/alacritty.toml ~/.config/velacritty/velacritty.toml`

### Default Behavior Changes

Velacritty identifies itself with its own branding by default:
- **Window title:** "Velacritty" (instead of "Alacritty")
- **Window class:** "Velacritty" (instead of "Alacritty")

If you use window manager rules (i3, sway, Hyprland, etc.), you'll need to update them to match the new class name. See [MIGRATION.md](MIGRATION.md) for detailed instructions.

To keep the original "Alacritty" branding, add this to your config:
```toml
[window]
title = "Alacritty"
class = { general = "Alacritty", instance = "Alacritty" }
```

For configuration documentation, see the man pages (`man 5 alacritty`) or consult the [Alacritty configuration documentation](https://alacritty.org/config-alacritty.html).

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Before contributing significant changes, please open an issue to discuss your proposed modifications.

---

## FAQ

**_What's the relationship between Velacritty and Alacritty?_**

Velacritty is a fork of Alacritty that aims to add enhanced visual features while maintaining the performance and reliability that makes Alacritty exceptional. We regularly sync with upstream Alacritty to incorporate bug fixes and new features.

**_Can I use my existing Alacritty config?_**

Velacritty uses a configuration format compatible with Alacritty, but with its own config file paths (`~/.config/velacritty/velacritty.toml`). You can migrate your existing Alacritty config by copying it to the Velacritty location. Note that the default window title and class are now "Velacritty" instead of "Alacritty" — if you use window manager rules, see [MIGRATION.md](MIGRATION.md) for update instructions.

**_Is it as fast as Alacritty?_**

Yes — Velacritty inherits Alacritty's GPU-accelerated rendering architecture and maintains the same performance characteristics. Any visual enhancements are designed to have minimal performance impact.

**_Why fork instead of contributing upstream?_**

Some features in Velacritty explore design directions that may not align with Alacritty's minimalist philosophy. We deeply respect Alacritty's focused approach and created this fork to experiment with additional features while maintaining the option to contribute appropriate improvements back upstream.

---

## License

Velacritty is released under dual license:

- **Apache License, Version 2.0** ([LICENSE-APACHE](LICENSE-APACHE))
- **MIT License** ([LICENSE-MIT](LICENSE-MIT))

You may choose either license for your use of this software.

### Original Alacritty Copyright

This project contains substantial code from Alacritty:

```
Copyright 2020 The Alacritty Project
Licensed under Apache License, Version 2.0 and MIT License
```

See [NOTICE](NOTICE) file for complete attribution details.

---

## Resources

- **Repository:** https://github.com/CoderDayton/velacritty
- **Original Alacritty:** https://github.com/alacritty/alacritty
- **Alacritty Website:** https://alacritty.org
- **Issue Tracker:** https://github.com/CoderDayton/velacritty/issues

---

## Further Reading

**About Alacritty** (the foundation of Velacritty):
- [Announcing Alacritty, a GPU-Accelerated Terminal Emulator](https://jwilm.io/blog/announcing-alacritty/) — January 6, 2017
- [A talk about Alacritty at the Rust Meetup](https://www.youtube.com/watch?v=qHOdYO3WUTk) — January 19, 2017
- [Alacritty Lands Scrollback, Publishes Benchmarks](https://jwilm.io/blog/alacritty-lands-scrollback/) — September 17, 2018
