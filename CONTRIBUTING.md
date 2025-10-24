# Contributing to Velacritty

Thank you for your interest in contributing to Velacritty!

> **Note:** Velacritty is a fork of [Alacritty](https://github.com/alacritty/alacritty). While we maintain our own development direction, we deeply appreciate and often sync with upstream Alacritty improvements. Consider contributing bug fixes to upstream Alacritty as well.

Table of Contents:

1. [Feature Requests](#feature-requests)
2. [Bug Reports](#bug-reports)
3. [Patches / Pull Requests](#patches--pull-requests)
    1. [Testing](#testing)
    2. [Performance](#performance)
    3. [Documentation](#documentation)
    4. [Style](#style)
4. [Upstream Synchronization](#upstream-synchronization)
5. [Contact](#contact)

## Feature Requests

Feature requests should be reported in the
[Velacritty issue tracker](https://github.com/CoderDayton/velacritty/issues). To reduce the number of
duplicates, please make sure to check the existing
[enhancement](https://github.com/CoderDayton/velacritty/issues?utf8=%E2%9C%93&q=is%3Aissue+label%3Aenhancement)
issues.

If your feature request would benefit the broader terminal emulator ecosystem and aligns with Alacritty's philosophy, consider proposing it to [upstream Alacritty](https://github.com/alacritty/alacritty/issues) as well.

## Bug Reports

Bug reports should be reported in the
[Velacritty issue tracker](https://github.com/CoderDayton/velacritty/issues).

**For bugs that exist in upstream Alacritty:** Please report them to the [Alacritty issue tracker](https://github.com/alacritty/alacritty/issues) so the entire community can benefit from the fix.

If a bug was not present in a previous version of Velacritty, providing the exact commit which
introduced the regression helps out a lot.

## Patches / Pull Requests

All patches have to be sent on GitHub as [pull requests](https://github.com/CoderDayton/velacritty/pulls).

If you are looking for a place to start contributing to Velacritty, take a look at the
[help wanted](https://github.com/CoderDayton/velacritty/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22)
and
[good first issue](https://github.com/CoderDayton/velacritty/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22)
issues.

You can find the minimum supported Rust version in Velacritty's manifest file
(`cat velacritty/Cargo.toml | grep "rust-version"`). Velacritty **must** always
build with the MSRV and bumping it should be avoided if possible.

Since `alacritty_terminal`'s version always tracks the next release, make sure that the version is
bumped according to semver when necessary.

### Pre-Commit Setup

Velacritty uses [pre-commit](https://pre-commit.com) to enforce code quality checks before commits. This ensures all contributions meet the project's style and quality standards.

**Installation:**

1. Install pre-commit if you don't have it:
   ```bash
   pip install pre-commit
   ```

2. Install the git hooks:
   ```bash
   pre-commit install
   ```

3. (Optional) Install pre-push hooks for additional validation:
   ```bash
   pre-commit install --hook-type pre-push
   ```

**What gets checked:**

- **Code formatting** (rustfmt): Automatic formatting compliance
- **Linting** (cargo clippy): Rust idioms and potential bugs (strict mode: all warnings denied)
- **Build** (cargo check): Package compiles without errors
- **General checks**: YAML, trailing whitespace, merge conflicts, etc.

**Running manually:**

To run checks on all files without committing:
```bash
pre-commit run --all-files
```

To run checks on staged files only:
```bash
pre-commit run
```

**Bypassing checks (not recommended):**

If absolutely necessary, you can skip pre-commit checks with:
```bash
git commit --no-verify
```

This should only be used for emergency hotfixes. The checks exist to maintain code quality.

### Testing

To make sure no regressions were introduced, all tests should be run before sending a pull request.
The following command can be run to test Velacritty:

```
cargo test
```

Additionally if there's any functionality included which would lend itself to additional testing,
new tests should be added. These can either be in the form of Rust tests using the `#[test]`
annotation, or ref tests (inherited from Alacritty).

To record a new ref test, a release version of the patched binary should be created and run with the
`--ref-test` flag. After closing the window, or killing it (`exit` and `^D` do not work),
some new files should have been generated in the working directory. Those can then be copied to the
`./tests/ref/NEW_TEST_NAME` directory and the test can be enabled by editing the `ref_tests!` macro
in the `./tests/ref.rs` file. When fixing a bug, it should be checked that the ref test does not
complete correctly with the unpatched version, to make sure the test case is covered properly.

### Performance

If changes could affect throughput or latency of Velacritty, these aspects should be benchmarked to
prevent potential regressions. Since there are often big performance differences between Rust's
nightly releases, it's advised to perform these tests on the latest Rust stable release.

Velacritty uses the [vtebench](https://github.com/alacritty/vtebench) tool (from upstream Alacritty) for testing performance. Instructions on how to use it can be found in its
[README](https://github.com/alacritty/vtebench/blob/master/README.md).

Latency is another important factor. On X11, Windows, and macOS the
[typometer](https://github.com/pavelfatin/typometer) tool allows measuring keyboard latency.

### Documentation

Code should be documented where appropriate. The existing code can be used as a guidance here and
the general `rustfmt` rules can be followed for formatting.

If any change has been made to the `config.rs` file, it should also be documented in the man pages.

Changes compared to the latest Velacritty release which have a direct effect on the user (opposed to
things like code refactorings or documentation/tests) additionally need to be documented in the
`CHANGELOG.md`. When a notable change is made to `alacritty_terminal`, it should be documented in
`alacritty_terminal/CHANGELOG.md` as well. The existing entries should be used as a style guideline.
The change log should be used to document changes from a user-perspective, instead of explaining the
technical background (like commit messages). More information about change log format can
be found [here](https://keepachangelog.com).

### Style

All Velacritty changes are automatically verified by CI to conform to its rustfmt guidelines. If a CI
build is failing because of formatting issues, you can install rustfmt using `rustup component add
rustfmt` and then format all code using `cargo fmt`.

Unless otherwise specified, Velacritty follows the Rust compiler's style guidelines:

https://rust-lang.github.io/api-guidelines

All comments should be fully punctuated with a trailing period. This applies both to regular and
documentation comments.

## Upstream Synchronization

Velacritty periodically syncs with upstream Alacritty to incorporate bug fixes, performance improvements, and new features. When contributing:

1. **Check upstream first:** If your change is a general improvement (bug fix, performance optimization, cross-platform compatibility), consider contributing to [Alacritty](https://github.com/alacritty/alacritty) so both projects benefit.

2. **Maintain compatibility:** When possible, maintain compatibility with Alacritty's configuration format and behavior to ease migration between the projects.

3. **Attribution:** When cherry-picking upstream commits, preserve original authorship and add notes in commit messages.

## Contact

If there are any outstanding questions about contributing to Velacritty, they can be asked on the
[Velacritty issue tracker](https://github.com/CoderDayton/velacritty/issues).

For questions about the original Alacritty codebase, you can also consult:
- [Alacritty issue tracker](https://github.com/alacritty/alacritty/issues)
- IRC channel `#alacritty` on Libera.Chat
