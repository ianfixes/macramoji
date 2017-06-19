# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- "built-in" emoji, courtesy of `emoji-datasource-apple`

### Changed

### Deprecated

### Removed

### Fixed

### Security


## [0.1.3] - 2017-06-19
### Added
- `firstframe` and `lastframe` gif animation extractors
- Wrapper for `gm.identify` to determine whether something is animated

### Changed
- test report is factored a bit better
- animation detection its own function

### Fixed
- `intensifies` uses the final frame of an input animation instead of mangling several frames
- `splosion` coalesces any input animation
- `dealwithit` glasses enter from the correct spot (top of image) even for small images
- `dealwithit` glasses enter after animation completes
- normalization of image sizes now handles gifs properly


## [0.1.2] - 2017-06-16
### Added
- `skintone_x` modifiers where `1 <= x <= 6`

### Changed
- test report now shows transparency

### Fixed
- Typos in CONTRIBUTING.md


## [0.1.1] - 2017-06-16
### Added
- `intensifies` macro
- `CONTRIBUTING.md` instructions (mostly for myself)

### Changed
- delays in `dealwithit` are better

### Fixed
- animations are more correctly detected for `splosion`

## 0.1.0 - 2017-06-15
### Added
- The entire initial release, enabling `splosion` and `dealwithit` macros.
- 2 debug macros `identity` and `identity-gm`

[Unreleased]: https://github.com/ifreecarve/macramoji/compare/v0.1.3...HEAD
[0.1.3]: https://github.com/ifreecarve/macramoji/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/ifreecarve/macramoji/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/ifreecarve/macramoji/compare/v0.1.0...v0.1.1
