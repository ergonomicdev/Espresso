# Contributing

Thanks for helping! Espresso is meant to stay small: a menu bar toggle that keeps the Mac awake and nothing more.

## Setup

See the [README](README.md#development). In short: install Xcode, then `make test`.

## Guidelines

- **Never leave the Mac awake by accident.** Every path that turns Espresso off (toggle, timer expiry, quit) must release the power assertion. Changes to `AwakeController` or `SleepAssertion` need unit tests in `Tests/EspressoCoreTests`.
- Keep logic that doesn't need AppKit in `EspressoCore`, so it stays testable.
- Keep the app menu-bar-only: no Dock icon and no windows beyond standard panels.
- Keep the UI free of SwiftUI macros like `@State` if practical, so the project builds with Command Line Tools.
- Don't edit `Espresso.xcodeproj` by hand: edit `project.yml` and run `make project`.

## Pull requests

1. Fork and create a branch.
2. Run `make test` (CI also runs `swift build`, `swift test` and an `xcodebuild` build).
3. Describe what changed and how you tested it.

By contributing you agree your work is released under the [MIT License](LICENSE).
