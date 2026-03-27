# philiprehberger-memo

[![Tests](https://github.com/philiprehberger/rb-memo/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-memo/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-memo.svg)](https://rubygems.org/gems/philiprehberger-memo)
[![License](https://img.shields.io/github/license/philiprehberger/rb-memo)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Practical memoization with TTL, LRU eviction, and thread-safety

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-memo"
```

Or install directly:

```bash
gem install philiprehberger-memo
```

## Usage

```ruby
require "philiprehberger/memo"

class UserService
  include Philiprehberger::Memo

  def find(id)
    User.find(id)
  end
  memo :find

  def expensive_query(filters)
    # ...
  end
  memo :expensive_query, ttl: 300

  def config
    # ...
  end
  memo :config, max_size: 100
end

service = UserService.new
service.find(1)           # executes query
service.find(1)           # returns cached result
service.clear_memo(:find) # manual invalidation
service.clear_all_memos   # clear everything
```

### Features

- Per-instance caching (not class-level)
- Handles `nil` and `false` return values correctly
- Optional TTL (time-based expiration)
- Optional max_size with LRU eviction
- Thread-safe with per-instance mutex
- Works with positional and keyword arguments

## API

### `Philiprehberger::Memo` (mixin)

| Method | Description |
|--------|-------------|
| `memo :method_name, ttl: nil, max_size: nil` | Memoize a method with optional TTL and LRU eviction (class-level) |
| `#clear_memo(method_name)` | Clear cached results for a specific memoized method |
| `#clear_all_memos` | Clear all memoized caches on the instance |

### `Philiprehberger::Memo::Cache`

| Method | Description |
|--------|-------------|
| `.new(ttl: nil, max_size: nil)` | Create a cache with optional TTL (seconds) and max size |
| `#get(key)` | Fetch a cached value; returns `[found, value]` |
| `#set(key, value)` | Store a value in the cache |
| `#clear` | Remove all entries from the cache |

### `Philiprehberger::Memo::Wrapper`

| Method | Description |
|--------|-------------|
| `.apply(klass, method_name, ttl:, max_size:)` | Wrap a method with memoization via `define_method` |

### `Philiprehberger::Memo::Error`

| Method | Description |
|--------|-------------|
| `.new(...)` | Custom error class for memo-related failures (inherits `StandardError`) |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
