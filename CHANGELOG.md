# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] - 2026-03-26

### Changed
- Add Sponsor badge to README
- Fix License section format
- Sync gemspec summary with README


## [0.2.1] - 2026-03-24

### Changed
- Expand README API table to document all public methods

## [0.2.0] - 2026-03-24

### Fixed
- Align README one-liner with gemspec summary

## [0.1.9] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.8] - 2026-03-23

### Fixed
- Standardize README to match template guide

## [0.1.7] - 2026-03-22

### Changed
- Expand test coverage

## [0.1.6] - 2026-03-20

### Fixed
- Fix README description trailing period
- Fix CHANGELOG header wording

## [0.1.5] - 2026-03-20

### Changed
- Restructure CHANGELOG.md to follow Keep a Changelog format

## [0.1.4] - 2026-03-20

### Changed
- Revert gemspec to single-quoted strings per RuboCop default configuration

## [0.1.3] - 2026-03-20

### Fixed
- Fix RuboCop Style/StringLiterals violations in gemspec

## [0.1.2] - 2026-03-20

### Added
- Add License badge to README
- Add bug_tracker_uri to gemspec

## [0.1.0] - 2026-03-15

### Added
- Initial release
- Method memoization via memo class method decorator
- TTL-based cache expiration
- LRU eviction with configurable max_size
- Per-instance thread-safe caches with proper nil/false handling
