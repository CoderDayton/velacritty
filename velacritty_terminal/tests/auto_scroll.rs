// Auto-scroll feature integration tests
// Tests the scrolling.auto_scroll configuration option behavior

use velacritty_terminal::event::{Event, EventListener};
use velacritty_terminal::grid::{Dimensions, Scroll};
use velacritty_terminal::term::test::TermSize;
use velacritty_terminal::term::{Config, Term};
use velacritty_terminal::vte::ansi;

// Mock event listener for testing
#[derive(Copy, Clone)]
struct Mock;

impl EventListener for Mock {
    fn send_event(&self, _event: Event) {}
}

/// Helper to write data to terminal using VTE parser
fn write_to_term<T: EventListener>(term: &mut Term<T>, data: &[u8]) {
    let mut parser: ansi::Processor = ansi::Processor::new();
    parser.advance(term, data);
}

#[test]
fn config_default_has_auto_scroll_true() {
    let config = Config::default();
    assert!(
        config.auto_scroll,
        "Default config must have auto_scroll=true for backward compatibility"
    );
}

#[test]
fn auto_scroll_false_config_creates_successfully() {
    let config = Config { auto_scroll: false, ..Default::default() };
    assert!(!config.auto_scroll, "Should be able to create config with auto_scroll=false");
}

#[test]
fn scroll_display_works_with_auto_scroll_true() {
    let size = TermSize::new(10, 5);
    let config = Config { auto_scroll: true, ..Default::default() };
    let mut term = Term::new(config, &size, Mock);

    // Fill terminal with lines beyond viewport (20 lines in 5-line viewport)
    for i in 0..20 {
        write_to_term(&mut term, format!("line {}\r\n", i).as_bytes());
    }

    // Scroll up manually
    term.scroll_display(Scroll::Delta(5));
    assert!(term.grid().display_offset() > 0, "Should be scrolled up after Delta(5)");

    // Verify scroll to bottom works
    term.scroll_display(Scroll::Bottom);
    assert_eq!(term.grid().display_offset(), 0, "Scroll::Bottom should reset display_offset to 0");
}

#[test]
fn scroll_display_works_with_auto_scroll_false() {
    let size = TermSize::new(10, 5);
    let config = Config { auto_scroll: false, ..Default::default() };
    let mut term = Term::new(config, &size, Mock);

    // Fill terminal
    for i in 0..20 {
        write_to_term(&mut term, format!("line {}\r\n", i).as_bytes());
    }

    // Explicit scroll commands should work regardless of auto_scroll setting
    term.scroll_display(Scroll::Delta(5));
    assert!(term.grid().display_offset() > 0, "Scroll::Delta should work");

    term.scroll_display(Scroll::Bottom);
    assert_eq!(term.grid().display_offset(), 0, "Scroll::Bottom should work");

    term.scroll_display(Scroll::Top);
    assert!(term.grid().display_offset() > 0, "Scroll::Top should work");
}

#[test]
fn grid_maintains_history_with_auto_scroll_false() {
    let size = TermSize::new(10, 5);
    let config = Config { auto_scroll: false, scrolling_history: 100, ..Default::default() };
    let mut term = Term::new(config, &size, Mock);

    // Fill terminal beyond viewport
    for i in 0..15 {
        write_to_term(&mut term, format!("line {:02}\r\n", i).as_bytes());
    }

    // Scroll up
    term.scroll_display(Scroll::Delta(3));
    let offset_after_scroll = term.grid().display_offset();
    assert!(offset_after_scroll > 0, "Should be scrolled up");

    // Write more content (simulating PTY output)
    write_to_term(&mut term, b"new line\r\n");

    // Grid should maintain history regardless of auto_scroll setting
    // (This is a terminal core behavior, not event handler behavior)
    // The offset might change due to grid scrolling, but history is preserved
    // This test verifies the config is accepted and grid still functions
    assert!(
        term.grid().total_lines() > term.grid().screen_lines(),
        "Grid should have scrollback history"
    );
}
