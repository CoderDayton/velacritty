use std::fmt::{self, Display, Formatter};
use std::path::{Path, PathBuf};
use std::result::Result as StdResult;
use std::{env, fs, io};

use log::{debug, error, info, warn};
use serde::Deserialize;
use serde_yaml::Error as YamlError;
use toml::de::Error as TomlError;
use toml::ser::Error as TomlSeError;
use toml::{Table, Value};

pub mod bell;
pub mod color;
pub mod cursor;
pub mod debug;
pub mod font;
pub mod general;
pub mod monitor;
pub mod scrolling;
pub mod selection;
pub mod serde_utils;
pub mod terminal;
pub mod ui_config;
pub mod window;

mod bindings;
mod mouse;

use crate::cli::Options;
#[cfg(test)]
pub use crate::config::bindings::Binding;
pub use crate::config::bindings::{
    Action, BindingKey, BindingMode, KeyBinding, MouseAction, SearchAction, ViAction,
};
pub use crate::config::ui_config::UiConfig;
use crate::logging::LOG_TARGET_CONFIG;

/// Maximum number of depth for the configuration file imports.
pub const IMPORT_RECURSION_LIMIT: usize = 5;

/// Default configuration template generated on first run.
const DEFAULT_CONFIG_TEMPLATE: &str = r##"# Velacritty Configuration
# This file was auto-generated on first run.
# See: https://github.com/yourusername/velacritty for documentation.

# ┌──────────────────────────────────────────────────────────────┐
# │ FONT CONFIGURATION                                           │
# └──────────────────────────────────────────────────────────────┘
# Font family and size impact readability and performance.
# Recommendation: Use a Nerd Font for icon/glyph support.
# Popular choices: MesloLGM Nerd Font, FiraCode Nerd Font, JetBrainsMono Nerd Font

[font]
size = 18.0

[font.normal]
family = "MesloLGM Nerd Font"
style = "Regular"

[font.bold]
family = "MesloLGM Nerd Font"
style = "Bold"

[font.italic]
family = "MesloLGM Nerd Font"
style = "Italic"

[font.bold_italic]
family = "MesloLGM Nerd Font"
style = "Bold Italic"

# ┌──────────────────────────────────────────────────────────────┐
# │ WINDOW CONFIGURATION                                         │
# └──────────────────────────────────────────────────────────────┘

[window]
# Window opacity (0.0 = fully transparent, 1.0 = opaque)
opacity = 0.95

# Padding around terminal content (in pixels)
[window.padding]
x = 10
y = 10

# Window decorations
# - Full: Borders and title bar
# - None: No borders or title bar
# - Transparent: Title bar, transparent background
# - Buttonless: Title bar, no minimize/close buttons
decorations = "Full"

# Startup mode
# - Windowed
# - Maximized
# - Fullscreen
# - SimpleFullscreen (macOS only)
startup_mode = "Windowed"

# ┌──────────────────────────────────────────────────────────────┐
# │ SCROLLING CONFIGURATION                                      │
# └──────────────────────────────────────────────────────────────┘

[scrolling]
# Maximum scrollback buffer lines (0 disables scrollback)
history = 5000

# Lines per scroll event (mouse wheel/touchpad)
multiplier = 3

# Auto-scroll to bottom on new output
# Set to false to freeze viewport (useful for TUI apps like htop)
# Toggle at runtime: Shift+Ctrl+A
auto_scroll = true

# ┌──────────────────────────────────────────────────────────────┐
# │ CURSOR CONFIGURATION                                         │
# └──────────────────────────────────────────────────────────────┘

[cursor]
# Cursor style options:
# - Block, Underline, Beam
[cursor.style]
shape = "Block"
blinking = "On"

# Blink interval (milliseconds)
blink_interval = 750

# Cursor will stop blinking after being idle for this duration (seconds)
# Set to 0 to never stop blinking
blink_timeout = 0

# ┌──────────────────────────────────────────────────────────────┐
# │ COLOR SCHEME (Catppuccin-inspired Dark Theme)                │
# └──────────────────────────────────────────────────────────────┘

[colors.primary]
background = "#1e1e2e"  # Base
foreground = "#cdd6f4"  # Text

[colors.cursor]
text = "#1e1e2e"        # Base
cursor = "#f5e0dc"      # Rosewater

[colors.vi_mode_cursor]
text = "#1e1e2e"        # Base
cursor = "#b4befe"      # Lavender

[colors.search.matches]
foreground = "#1e1e2e"  # Base
background = "#a6adc8"  # Subtext0

[colors.search.focused_match]
foreground = "#1e1e2e"  # Base
background = "#a6e3a1"  # Green

[colors.hints.start]
foreground = "#1e1e2e"  # Base
background = "#f9e2af"  # Yellow

[colors.hints.end]
foreground = "#1e1e2e"  # Base
background = "#a6adc8"  # Subtext0

[colors.selection]
text = "CellForeground"
background = "#45475a"  # Surface1

# Normal colors
[colors.normal]
black = "#45475a"       # Surface1
red = "#f38ba8"         # Red
green = "#a6e3a1"       # Green
yellow = "#f9e2af"      # Yellow
blue = "#89b4fa"        # Blue
magenta = "#f5c2e7"     # Pink
cyan = "#94e2d5"        # Teal
white = "#bac2de"       # Subtext1

# Bright colors
[colors.bright]
black = "#585b70"       # Surface2
red = "#f38ba8"         # Red
green = "#a6e3a1"       # Green
yellow = "#f9e2af"      # Yellow
blue = "#89b4fa"        # Blue
magenta = "#f5c2e7"     # Pink
cyan = "#94e2d5"        # Teal
white = "#a6adc8"       # Subtext0

# ┌──────────────────────────────────────────────────────────────┐
# │ BELL CONFIGURATION                                           │
# └──────────────────────────────────────────────────────────────┘

[bell]
# Visual bell animation
# - Ease | EaseOut | EaseOutSine | EaseOutQuad | EaseOutCubic | EaseOutQuart | EaseOutQuint | EaseOutExpo | EaseOutCirc | Linear
animation = "EaseOutExpo"

# Duration of visual bell (milliseconds)
duration = 0

# Visual bell color
color = "#f5e0dc"  # Rosewater

# ┌──────────────────────────────────────────────────────────────┐
# │ SELECTION CONFIGURATION                                      │
# └──────────────────────────────────────────────────────────────┘

[selection]
# Characters considered part of a word for double-click selection
semantic_escape_chars = ",│`|:\"' ()[]{}<>\t"

# When enabled, selected text is automatically copied to clipboard
save_to_clipboard = false

# ┌──────────────────────────────────────────────────────────────┐
# │ TERMINAL CONFIGURATION                                       │
# └──────────────────────────────────────────────────────────────┘

[terminal]
# OSC 52 clipboard interaction (copy/paste via escape sequences)
# - Disabled: Ignore OSC 52
# - OnlyCopy: Allow copying only
# - OnlyPaste: Allow pasting only
# - CopyPaste: Allow both
osc52 = "CopyPaste"

# ┌──────────────────────────────────────────────────────────────┐
# │ MOUSE CONFIGURATION                                          │
# └──────────────────────────────────────────────────────────────┘

[mouse]
# Hide mouse cursor when typing
hide_when_typing = true

# ┌──────────────────────────────────────────────────────────────┐
# │ KEYBOARD HINTS (URL/PATH DETECTION)                          │
# └──────────────────────────────────────────────────────────────┘

[[hints.enabled]]
# Regex for URLs
regex = "(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^\u0000-\u001F\u007F-\u009F<>\"\\s{-}\\^⟨⟩`]+"

# Open with default handler (xdg-open, open, start)
[[hints.enabled.binding]]
key = "U"
mods = "Control|Shift"

[hints.enabled.mouse]
enabled = true

# ┌──────────────────────────────────────────────────────────────┐
# │ KEY BINDINGS (CUSTOM)                                        │
# └──────────────────────────────────────────────────────────────┘
# Uncomment and modify as needed. See documentation for available actions.

# [[keyboard.bindings]]
# key = "N"
# mods = "Control|Shift"
# action = "CreateNewWindow"

# [[keyboard.bindings]]
# key = "Plus"
# mods = "Control"
# action = "IncreaseFontSize"

# [[keyboard.bindings]]
# key = "Minus"
# mods = "Control"
# action = "DecreaseFontSize"
"##;

/// Result from config loading.
pub type Result<T> = std::result::Result<T, Error>;

/// Errors occurring during config loading.
#[derive(Debug)]
pub enum Error {
    /// Couldn't read $HOME environment variable.
    ReadingEnvHome(env::VarError),

    /// io error reading file.
    Io(io::Error),

    /// Invalid toml.
    Toml(TomlError),

    /// Failed toml serialization.
    TomlSe(TomlSeError),

    /// Invalid yaml.
    Yaml(YamlError),
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Error::ReadingEnvHome(err) => err.source(),
            Error::Io(err) => err.source(),
            Error::Toml(err) => err.source(),
            Error::TomlSe(err) => err.source(),
            Error::Yaml(err) => err.source(),
        }
    }
}

impl Display for Error {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Error::ReadingEnvHome(err) => {
                write!(f, "Unable to read $HOME environment variable: {err}")
            },
            Error::Io(err) => write!(f, "Error reading config file: {err}"),
            Error::Toml(err) => write!(f, "Config error: {err}"),
            Error::TomlSe(err) => write!(f, "Yaml conversion error: {err}"),
            Error::Yaml(err) => write!(f, "Config error: {err}"),
        }
    }
}

impl From<env::VarError> for Error {
    fn from(val: env::VarError) -> Self {
        Error::ReadingEnvHome(val)
    }
}

impl From<io::Error> for Error {
    fn from(val: io::Error) -> Self {
        Error::Io(val)
    }
}

impl From<TomlError> for Error {
    fn from(val: TomlError) -> Self {
        Error::Toml(val)
    }
}

impl From<TomlSeError> for Error {
    fn from(val: TomlSeError) -> Self {
        Error::TomlSe(val)
    }
}

impl From<YamlError> for Error {
    fn from(val: YamlError) -> Self {
        Error::Yaml(val)
    }
}

/// Generate a default configuration file if none exists.
///
/// Returns the path to the generated config file, or `None` if generation failed.
fn generate_default_config() -> Option<PathBuf> {
    // Determine config directory based on platform
    let config_dir = get_default_config_dir()?;

    // Create the directory if it doesn't exist
    if let Err(err) = fs::create_dir_all(&config_dir) {
        error!(target: LOG_TARGET_CONFIG, "Failed to create config directory {config_dir:?}: {err}");
        return None;
    }

    // Build path to velacritty.toml
    let config_path = config_dir.join("velacritty.toml");

    // Write the default template
    if let Err(err) = fs::write(&config_path, DEFAULT_CONFIG_TEMPLATE) {
        error!(target: LOG_TARGET_CONFIG, "Failed to write default config to {config_path:?}: {err}");
        return None;
    }

    info!(target: LOG_TARGET_CONFIG, "Generated default configuration at: {config_path:?}");
    Some(config_path)
}

/// Get the default configuration directory path based on platform.
#[cfg(not(windows))]
fn get_default_config_dir() -> Option<PathBuf> {
    // Try XDG_CONFIG_HOME/velacritty first
    let xdg = xdg::BaseDirectories::with_prefix("velacritty");
    xdg.get_config_home().or_else(|| {
        // Fallback to $HOME/.config/velacritty
        env::var("HOME").ok().map(|home| PathBuf::from(home).join(".config").join("velacritty"))
    })
}

#[cfg(windows)]
fn get_default_config_dir() -> Option<PathBuf> {
    // Use %APPDATA%\velacritty on Windows
    dirs::config_dir().map(|path| path.join("velacritty"))
}

/// Load the configuration file.
pub fn load(options: &mut Options) -> UiConfig {
    let config_path = options
        .config_file
        .clone()
        .or_else(|| installed_config("toml"))
        .or_else(|| installed_config("yml"));

    // Load the config using the following fallback behavior:
    //  - Config path + CLI overrides
    //  - CLI overrides
    //  - Default (with auto-generation)
    let mut config = config_path
        .as_ref()
        .and_then(|config_path| load_from(config_path).ok())
        .unwrap_or_else(|| {
            let mut config = UiConfig::default();
            match config_path {
                Some(config_path) => config.config_paths.push(config_path),
                None => {
                    info!(target: LOG_TARGET_CONFIG, "No config file found; using default");
                    // Auto-generate default config file
                    if let Some(generated_path) = generate_default_config() {
                        info!(target: LOG_TARGET_CONFIG, "Generated default config at: {generated_path:?}");
                        config.config_paths.push(generated_path);
                    }
                },
            }
            config
        });

    after_loading(&mut config, options);

    config
}

/// Attempt to reload the configuration file.
pub fn reload(config_path: &Path, options: &mut Options) -> Result<UiConfig> {
    debug!("Reloading configuration file: {config_path:?}");

    // Load config, propagating errors.
    let mut config = load_from(config_path)?;

    after_loading(&mut config, options);

    Ok(config)
}

/// Modifications after the `UiConfig` object is created.
fn after_loading(config: &mut UiConfig, options: &mut Options) {
    // Override config with CLI options.
    options.override_config(config);
}

/// Load configuration file and log errors.
fn load_from(path: &Path) -> Result<UiConfig> {
    match read_config(path) {
        Ok(config) => Ok(config),
        Err(Error::Io(io)) if io.kind() == io::ErrorKind::NotFound => {
            error!(target: LOG_TARGET_CONFIG, "Unable to load config {path:?}: File not found");
            Err(Error::Io(io))
        },
        Err(err) => {
            error!(target: LOG_TARGET_CONFIG, "Unable to load config {path:?}: {err}");
            Err(err)
        },
    }
}

/// Deserialize configuration file from path.
fn read_config(path: &Path) -> Result<UiConfig> {
    let mut config_paths = Vec::new();
    let config_value = parse_config(path, &mut config_paths, IMPORT_RECURSION_LIMIT)?;

    // Deserialize to concrete type.
    let mut config = UiConfig::deserialize(config_value)?;
    config.config_paths = config_paths;

    Ok(config)
}

/// Deserialize all configuration files as generic Value.
fn parse_config(
    path: &Path,
    config_paths: &mut Vec<PathBuf>,
    recursion_limit: usize,
) -> Result<Value> {
    config_paths.push(path.to_owned());

    // Deserialize the configuration file.
    let config = deserialize_config(path, false)?;

    // Merge config with imports.
    let imports = load_imports(&config, path, config_paths, recursion_limit);
    Ok(serde_utils::merge(imports, config))
}

/// Deserialize a configuration file.
pub fn deserialize_config(path: &Path, warn_pruned: bool) -> Result<Value> {
    let mut contents = fs::read_to_string(path)?;

    // Remove UTF-8 BOM.
    if contents.starts_with('\u{FEFF}') {
        contents = contents.split_off(3);
    }

    // Convert YAML to TOML as a transitionary fallback mechanism.
    let extension = path.extension().unwrap_or_default();
    if (extension == "yaml" || extension == "yml") && !contents.trim().is_empty() {
        warn!(
            "YAML config {path:?} is deprecated, please migrate to TOML using `velacritty migrate`"
        );

        let mut value: serde_yaml::Value = serde_yaml::from_str(&contents)?;
        prune_yaml_nulls(&mut value, warn_pruned);
        contents = toml::to_string(&value)?;
    }

    // Load configuration file as Value.
    let config: Value = toml::from_str(&contents)?;

    Ok(config)
}

/// Load all referenced configuration files.
fn load_imports(
    config: &Value,
    base_path: &Path,
    config_paths: &mut Vec<PathBuf>,
    recursion_limit: usize,
) -> Value {
    // Get paths for all imports.
    let import_paths = match imports(config, base_path, recursion_limit) {
        Ok(import_paths) => import_paths,
        Err(err) => {
            error!(target: LOG_TARGET_CONFIG, "{err}");
            return Value::Table(Table::new());
        },
    };

    // Parse configs for all imports recursively.
    let mut merged = Value::Table(Table::new());
    for import_path in import_paths {
        let path = match import_path {
            Ok(path) => path,
            Err(err) => {
                error!(target: LOG_TARGET_CONFIG, "{err}");
                continue;
            },
        };

        match parse_config(&path, config_paths, recursion_limit - 1) {
            Ok(config) => merged = serde_utils::merge(merged, config),
            Err(Error::Io(io)) if io.kind() == io::ErrorKind::NotFound => {
                info!(target: LOG_TARGET_CONFIG, "Config import not found:\n  {:?}", path.display());
                continue;
            },
            Err(err) => {
                error!(target: LOG_TARGET_CONFIG, "Unable to import config {path:?}: {err}")
            },
        }
    }

    merged
}

/// Get all import paths for a configuration.
pub fn imports(
    config: &Value,
    base_path: &Path,
    recursion_limit: usize,
) -> StdResult<Vec<StdResult<PathBuf, String>>, String> {
    let imports =
        config.get("import").or_else(|| config.get("general").and_then(|g| g.get("import")));
    let imports = match imports {
        Some(Value::Array(imports)) => imports,
        Some(_) => return Err("Invalid import type: expected a sequence".into()),
        None => return Ok(Vec::new()),
    };

    // Limit recursion to prevent infinite loops.
    if !imports.is_empty() && recursion_limit == 0 {
        return Err("Exceeded maximum configuration import depth".into());
    }

    let mut import_paths = Vec::new();

    for import in imports {
        let path = match import {
            Value::String(path) => PathBuf::from(path),
            _ => {
                import_paths.push(Err("Invalid import element type: expected path string".into()));
                continue;
            },
        };

        let normalized = normalize_import(base_path, path);

        import_paths.push(Ok(normalized));
    }

    Ok(import_paths)
}

/// Normalize import paths.
pub fn normalize_import(base_config_path: &Path, import_path: impl Into<PathBuf>) -> PathBuf {
    let mut import_path = import_path.into();

    // Resolve paths relative to user's home directory.
    if let (Ok(stripped), Some(home_dir)) = (import_path.strip_prefix("~/"), home::home_dir()) {
        import_path = home_dir.join(stripped);
    }

    if import_path.is_relative() {
        if let Some(base_config_dir) = base_config_path.parent() {
            import_path = base_config_dir.join(import_path)
        }
    }

    import_path
}

/// Prune the nulls from the YAML to ensure TOML compatibility.
fn prune_yaml_nulls(value: &mut serde_yaml::Value, warn_pruned: bool) {
    fn walk(value: &mut serde_yaml::Value, warn_pruned: bool) -> bool {
        match value {
            serde_yaml::Value::Sequence(sequence) => {
                sequence.retain_mut(|value| !walk(value, warn_pruned));
                sequence.is_empty()
            },
            serde_yaml::Value::Mapping(mapping) => {
                mapping.retain(|key, value| {
                    let retain = !walk(value, warn_pruned);
                    if let Some(key_name) = key.as_str().filter(|_| !retain && warn_pruned) {
                        eprintln!("Removing null key \"{key_name}\" from the end config");
                    }
                    retain
                });
                mapping.is_empty()
            },
            serde_yaml::Value::Null => true,
            _ => false,
        }
    }

    if walk(value, warn_pruned) {
        // When the value itself is null return the mapping.
        *value = serde_yaml::Value::Mapping(Default::default());
    }
}

/// Get the location of the first found default config file paths
/// according to the following order:
///
/// 1. $XDG_CONFIG_HOME/velacritty/velacritty.toml
/// 2. $XDG_CONFIG_HOME/velacritty.toml
/// 3. $HOME/.config/velacritty/velacritty.toml
/// 4. $HOME/.velacritty.toml
/// 5. /etc/velacritty/velacritty.toml
#[cfg(not(windows))]
pub fn installed_config(suffix: &str) -> Option<PathBuf> {
    let file_name = format!("velacritty.{suffix}");

    // Try using XDG location by default.
    xdg::BaseDirectories::with_prefix("velacritty")
        .find_config_file(&file_name)
        .or_else(|| xdg::BaseDirectories::new().find_config_file(&file_name))
        .or_else(|| {
            if let Ok(home) = env::var("HOME") {
                // Fallback path: $HOME/.config/velacritty/velacritty.toml.
                let fallback = PathBuf::from(&home).join(".config/velacritty").join(&file_name);
                if fallback.exists() {
                    return Some(fallback);
                }
                // Fallback path: $HOME/.velacritty.toml.
                let hidden_name = format!(".{file_name}");
                let fallback = PathBuf::from(&home).join(hidden_name);
                if fallback.exists() {
                    return Some(fallback);
                }
            }

            let fallback = PathBuf::from("/etc/velacritty").join(&file_name);
            fallback.exists().then_some(fallback)
        })
}

#[cfg(windows)]
pub fn installed_config(suffix: &str) -> Option<PathBuf> {
    let file_name = format!("velacritty.{suffix}");
    dirs::config_dir()
        .map(|path| path.join("velacritty").join(file_name))
        .filter(|new| new.exists())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_config() {
        toml::from_str::<UiConfig>("").unwrap();
    }

    fn yaml_to_toml(contents: &str) -> String {
        let mut value: serde_yaml::Value = serde_yaml::from_str(contents).unwrap();
        prune_yaml_nulls(&mut value, false);
        toml::to_string(&value).unwrap()
    }

    #[test]
    fn yaml_with_nulls() {
        let contents = r#"
        window:
            blinking: Always
            cursor:
            not_blinking: Always
            some_array:
              - { window: }
              - { window: "Hello" }

        "#;
        let toml = yaml_to_toml(contents);
        assert_eq!(
            toml.trim(),
            r#"[window]
blinking = "Always"
not_blinking = "Always"

[[window.some_array]]
window = "Hello""#
        );
    }

    #[test]
    fn empty_yaml_to_toml() {
        let contents = r#"

        "#;
        let toml = yaml_to_toml(contents);
        assert!(toml.is_empty());
    }
}
