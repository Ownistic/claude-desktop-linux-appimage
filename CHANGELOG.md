# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2025-05-29

### Added
- Self-contained Electron runtime bundling - no more "electron: not found" errors
- Automatic platform detection with `--ozone-platform-hint=auto`
- Wayland window decorations support for better GNOME integration
- Independent AppImage versioning system separate from Claude Desktop version
- Comprehensive scaling and window management fixes for HiDPI displays

### Fixed
- **MAJOR**: Fixed "exec: electron: not found" error on systems without Electron installed
- **MAJOR**: Fixed GTK 2/3 + GTK 4 compatibility conflicts causing crashes on GNOME
- Fixed window size detection issues on GNOME with fractional scaling
- Fixed window resizing problems on Wayland
- Fixed architecture detection conflicts in AppImageTool
- Fixed desktop entry categories to avoid multiple main category warnings

### Changed
- Switched from system Electron dependency to bundled Electron runtime
- Updated Electron launch flags for better Linux compatibility:
  - Added `--gtk-version=3` to prevent GTK version conflicts
  - Added `--enable-features=WaylandWindowDecorations` for proper Wayland support
  - Added `--ozone-platform-hint=auto` for automatic platform detection
- Improved AppImage structure with dedicated Electron directory
- Enhanced build process with better error handling and architecture verification

### Technical Details
- Bundled Electron v36.3.2 for x86_64 architecture
- Compatible with Claude Desktop v0.9.3
- Fixed GTK version conflicts that caused crashes on Ubuntu 24.04+ and modern GNOME systems
- Improved compatibility with fractional scaling setups (125%, 150%, 175%, etc.)
- Better support for mixed DPI monitor configurations