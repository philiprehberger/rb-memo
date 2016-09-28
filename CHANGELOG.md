# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
