# Espresso

A tiny, native menu bar app for macOS that keeps your Mac awake, in the spirit of Caffeine. Click the cup to stop your Mac from going to sleep; click again to let it sleep normally.

## Features

- Lives in the menu bar only: no Dock icon, no windows
- **Left-click** the cup to turn keep-awake on or off. The icon is filled while active and outlined while inactive
- **Right-click** (or Control/Option-click) for the menu:
  - Status, with time remaining for timed sessions
  - **Activate For**: indefinitely, 5, 15 or 30 minutes, 1, 2 or 5 hours
  - **Default Duration**: what a left-click activates for (remembered)
  - **Launch at Login**
  - **About** and **Quit**
- Timed sessions end on their own; quitting always lets your Mac sleep again

Espresso holds an IOKit power assertion (`IOPMAssertionCreateWithName`, `PreventUserIdleDisplaySleep`) while active, which stops idle display and system sleep. It doesn't stop sleep when you close the lid or choose Apple menu › Sleep. To see it working:

```sh
pmset -g assertions | grep Espresso
```

## Requirements

- macOS 13 or later
- Xcode 16 or later to build from source

## Install

### Option 1: Homebrew (recommended)

```sh
brew install --cask ergonomicdev/tap/espresso
```

The cask removes the quarantine flag for you, because the app is not notarized (see Option 2).

### Option 2: download

1. Download `Espresso-<version>.dmg` from the [Releases](../../releases) page.
2. Open it and drag **Espresso** into **Applications**.
3. First launch: the app is ad-hoc signed, not notarized, so macOS Gatekeeper will block a plain double-click. **Right-click Espresso → Open → Open** once. If macOS still refuses, run `xattr -dr com.apple.quarantine /Applications/Espresso.app`.

The build is universal (Apple Silicon and Intel) and needs macOS 13 or later. After launching, look for the cup in the menu bar.

### Option 3: build from source

```sh
git clone https://github.com/ergonomicdev/Espresso.git && cd Espresso
make install     # builds a Release app and copies it to /Applications
```

Requires Xcode 16+. `make dmg` produces `dist/Espresso-<version>.dmg` and a `.zip` without installing.

## Quick start (development)

```sh
git clone https://github.com/ergonomicdev/Espresso.git && cd Espresso
make run      # or: swift run Espresso
make test     # or: swift test
```

`make help` lists all shortcuts. The Makefile uses `/Applications/Xcode.app` automatically if your selected developer directory isn't a full Xcode.

When run with `swift run`, Espresso isn't inside an `.app` bundle, so **Launch at Login** is disabled. Use `make app` (or Xcode) to try it.

## Development

### VS Code

1. Install Xcode and the recommended extensions (VS Code will prompt: *Swift*, *EditorConfig*).
2. Open the folder. Use **Run and Debug → Debug Espresso** (builds and launches with LLDB), or the **Run tests** task (`Terminal → Run Test Task`).

Notes:
- The app avoids SwiftUI macros, and the tests use Swift Testing, so both build and run with Command Line Tools alone.
- Don't point the Swift extension's `swift.path` at Xcode's toolchain: it has no `lldb-dap`, so debugging fails.
- A harmless `ld: warning: search path '/Library/Developer/CommandLineTools/...' not found` appears when building with Command Line Tools only; selecting Xcode removes it.

### Xcode

Open `Espresso.xcodeproj` (not the folder), choose the `Espresso` scheme → My Mac, and Run. This builds a real `.app` bundle with Info.plist and icon. The project is generated from `project.yml`; after changing it, run `make project` (requires [XcodeGen](https://github.com/yonaskolb/XcodeGen), `brew install xcodegen`). The bundle identifier `dev.espresso.Espresso` in `project.yml` is a placeholder: change it if you distribute your own build.

### Project layout

| Path | Purpose |
| --- | --- |
| `Sources/EspressoCore` | Power assertion, activation state and durations (no UI) |
| `Sources/Espresso` | Menu bar app: SwiftUI entry point, status item and menu, launch at login |
| `Tests/EspressoCoreTests` | Unit tests for activation, expiry and durations |
| `Tools/` | Icon generator and release packaging script |
| `Assets/` | Generated app icon (`.icns`, iconset, preview) |
| `Config/` | App `Info.plist` (`LSUIElement` hides the Dock icon) |

### Icon

`make icon` (`swift Tools/GenerateIcon.swift`) regenerates `Assets/AppIcon.icns`, the iconset and the preview.

## Releasing

Bump `MARKETING_VERSION` (and `CURRENT_PROJECT_VERSION`) in `project.yml`, run `make project`, commit, then push a tag such as `v1.0.0`. The Release workflow runs the tests, builds the universal app, and attaches the `.dmg` and `.zip` to a GitHub release. To make downloads open without the Gatekeeper warning you would need an Apple Developer ID signature and notarization, which aren't configured.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
