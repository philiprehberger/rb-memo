# philiprehberger-memo

[![Tests](https://github.com/philiprehberger/rb-memo/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-memo/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-memo.svg)](https://rubygems.org/gems/philiprehberger-memo)
[![License](https://img.shields.io/github/license/philiprehberger/rb-memo)](LICENSE)

Practical memoization — `memo` decorator with TTL, LRU eviction, thread-safety, and proper nil/false handling

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

## Features

- Per-instance caching (not class-level)
- Handles `nil` and `false` return values correctly
- Optional TTL (time-based expiration)
- Optional max_size with LRU eviction
- Thread-safe with per-instance mutex
- Works with positional and keyword arguments

## API

| Method | Description |
|--------|-------------|
| `memo :method_name, ttl: nil, max_size: nil` | Memoize a method (class-level) |
| `#clear_memo(:method_name)` | Clear cache for one method |
| `#clear_all_memos` | Clear all memoized caches |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
