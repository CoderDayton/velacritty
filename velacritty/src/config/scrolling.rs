use serde::de::Error as SerdeError;
use serde::{Deserialize, Deserializer, Serialize};

use velacritty_config_derive::{ConfigDeserialize, SerdeReplace};

/// Maximum scrollback amount configurable.
pub const MAX_SCROLLBACK_LINES: u32 = 100_000;

/// Default value for auto_scroll.
#[allow(dead_code)]
fn default_true() -> bool {
    true
}

/// Struct for scrolling related settings.
#[derive(ConfigDeserialize, Serialize, Copy, Clone, Debug, PartialEq, Eq)]
pub struct Scrolling {
    pub multiplier: u8,

    #[serde(default = "default_true")]
    pub auto_scroll: bool,

    history: ScrollingHistory,
}

impl Default for Scrolling {
    fn default() -> Self {
        Self { multiplier: 3, auto_scroll: true, history: Default::default() }
    }
}

impl Scrolling {
    pub fn history(self) -> u32 {
        self.history.0
    }
}

#[derive(SerdeReplace, Serialize, Copy, Clone, Debug, PartialEq, Eq)]
struct ScrollingHistory(u32);

impl Default for ScrollingHistory {
    fn default() -> Self {
        Self(10_000)
    }
}

impl<'de> Deserialize<'de> for ScrollingHistory {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let lines = u32::deserialize(deserializer)?;

        if lines > MAX_SCROLLBACK_LINES {
            Err(SerdeError::custom(format!(
                "exceeded maximum scrolling history ({lines}/{MAX_SCROLLBACK_LINES})"
            )))
        } else {
            Ok(Self(lines))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn auto_scroll_default_true() {
        let scrolling = Scrolling::default();
        assert!(scrolling.auto_scroll);
    }

    #[test]
    fn auto_scroll_deserialize_explicit_false() {
        let toml = r#"
            history = 5000
            multiplier = 5
            auto_scroll = false
        "#;
        let scrolling: Scrolling = toml::from_str(toml).unwrap();
        assert_eq!(scrolling.history(), 5000);
        assert_eq!(scrolling.multiplier, 5);
        assert!(!scrolling.auto_scroll);
    }

    #[test]
    fn auto_scroll_deserialize_explicit_true() {
        let toml = r#"
            history = 5000
            multiplier = 5
            auto_scroll = true
        "#;
        let scrolling: Scrolling = toml::from_str(toml).unwrap();
        assert!(scrolling.auto_scroll);
    }

    #[test]
    fn auto_scroll_deserialize_default_when_missing() {
        let toml = r#"
            history = 5000
            multiplier = 5
        "#;
        let scrolling: Scrolling = toml::from_str(toml).unwrap();
        assert!(scrolling.auto_scroll);
    }
}
