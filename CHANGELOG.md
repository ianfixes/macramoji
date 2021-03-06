# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security


## [0.2.2] - 2018-04-22
### Changed
 - Author name

## [0.2.1] - 2017-10-05
### Added
 - Early exit when there aren't any images to normalize
 - Entry points for adding individual temp `ImageContainer`s and `ImageResult`s to an `ImageResult`
 - Extra logging of output paths for ease of debugging
 - Normalize an image by path in addition to by `ImageResult`
 - More image-based tests
 - A way to mock temp image creation using `process.env.MACRAMOJI_DEBUG_TMP`

### Changed
 - Step-size and frame delay are now dynamic for `dealwithit`, so the observed speed of the glasses does not change in regard to input image size

### Fixed
 - Normalization operations no longer add a solid background to transparent animated gifs
 - Filenames in HTML reports of images now have extensions

## [0.1.10] - 2017-06-30
### Added
- Logging, to aid in troubleshooting

## [0.1.9] - 2017-06-29
### Added
- Complete end-to-end image generation artifact tests
- More logging for resultFromGM failures


## [0.1.8] - 2017-06-29
### Added
- `ImageContainer` now tracks `existingContainerCount` for debugging purposes
- Instrumentation for testing: `source` and `provenance` for tracking where images come from
- Logging for the number of temp images that disappeared after a cleanup operation

### Changed
- Centralized temp image roundup
- ImageWorker uses recursion instead of duplication to track resolved results

### Fixed
- `SlackResponse.cleanup` now actually calls lower-level cleanup
- Some tests weren't written with an async pattern when they needed to be
- `imageTransform.normalize()` wasn't using callbacks properly and failed to propagate temp images
- This changelog's links

## [0.1.7] - 2017-06-27
### Added
- `cleanup` now available in multiple classes and it's safe to call it more than once
- `respondBeepBoopSlashCommand` in the SlackResponse object


## [0.1.6] - 2017-06-25
### Added
- `EmojiStore` methods to `addEmoji` and `deleteEmoji`, presumably in response to RTM updates


## [0.1.5] - 2017-06-22
### Added
- `respondBotkit` function for future botkit integrations

### Changed
- `EmojiStore` constructor now takes an emoji-fetching function instead of a particular Slack API object
- `SlackResponse` object now uses `respondHubot` instead of `respond`, to make room for other types of responses
- `splosion` macro now uses 64x64 explosion gif, because the larger one looked pixely

### Fixed
- Emoji refresh had a missing reference to `this`.  It now properly refreshes on its timer.
- Explosion macro wasn't causing the original emoji to disappear as if exploded.


## [0.1.4] - 2017-06-19
### Added
- "built-in" emoji, courtesy of `emoji-datasource-apple`

### Changed
- required syntax loses the enclosing `:` characters


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


[Unreleased]: https://github.com/ianfixes/macramoji/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/ianfixes/macramoji/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/ianfixes/macramoji/compare/v0.1.10...v0.2.1
[0.1.10]: https://github.com/ianfixes/macramoji/compare/v0.1.9...v0.1.10
[0.1.9]: https://github.com/ianfixes/macramoji/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/ianfixes/macramoji/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/ianfixes/macramoji/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/ianfixes/macramoji/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/ianfixes/macramoji/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/ianfixes/macramoji/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/ianfixes/macramoji/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/ianfixes/macramoji/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/ianfixes/macramoji/compare/v0.1.0...v0.1.1
