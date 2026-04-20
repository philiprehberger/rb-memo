# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-04-20

### Added
- `Cache#age(key)` returns the seconds since an entry was last stored (`nil` when the key is missing or has expired). Does not affect hit/miss stats so it is safe for monitoring hot caches.

## [0.4.0] - 2026-04-15

### Added
- `#memoized?(method_name, *args, **kwargs)` instance method to check whether a non-expired cached value exists for a call without triggering it or affecting hit/miss stats
- `#cache_size(method_name)` instance method returning the number of cached entries for a memoized method (`0` when the method has no cache yet)
- `#memo_keys` instance method listing methods with live caches on the current instance
- `#forget_memo(method_name, *args, **kwargs)` instance method for surgical invalidation of a single cached call signature
- `Cache#key?(key)`, `Cache#delete(key)`, `Cache#keys`, and `Cache#prune_expired` for direct cache introspection and maintenance

## [0.3.0] - 2026-04-10

### Added
- `Cache#size` returns the current number of cached entries
- `Cache#stats` returns `{ hits:, misses:, hit_rate: }` for monitoring cache effectiveness
- `#memo_stats(method_name)` instance method for per-method cache stats
- Hit/miss counters tracked per cache, reset on `clear`

## [0.2.5] - 2026-04-08

### Changed
- Align gemspec summary with README description.

## [0.2.4] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.2.3] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

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

[Unreleased]: https://github.com/philiprehberger/rb-memo/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/philiprehberger/rb-memo/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/philiprehberger/rb-memo/compare/v0.2.5...v0.3.0
[0.2.5]: https://github.com/philiprehberger/rb-memo/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/philiprehberger/rb-memo/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/philiprehberger/rb-memo/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/philiprehberger/rb-memo/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/philiprehberger/rb-memo/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/philiprehberger/rb-memo/compare/v0.1.9...v0.2.0
[0.1.9]: https://github.com/philiprehberger/rb-memo/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/philiprehberger/rb-memo/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/philiprehberger/rb-memo/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/philiprehberger/rb-memo/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/philiprehberger/rb-memo/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/philiprehberger/rb-memo/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/philiprehberger/rb-memo/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/philiprehberger/rb-memo/compare/v0.1.0...v0.1.2
[0.1.0]: https://github.com/philiprehberger/rb-memo/releases/tag/v0.1.0
