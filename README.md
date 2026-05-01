# philiprehberger-memo

[![Tests](https://github.com/philiprehberger/rb-memo/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-memo/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-memo.svg)](https://rubygems.org/gems/philiprehberger-memo)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-memo)](https://github.com/philiprehberger/rb-memo/commits/main)

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

### Cache Stats

Monitor hit/miss ratios for tuning TTL and max_size:

```ruby
service = UserService.new
service.find(1)           # miss
service.find(1)           # hit
service.find(2)           # miss

service.memo_stats(:find)
# => { hits: 1, misses: 2, hit_rate: 0.3333 }
```

### Aggregate Stats Across All Memoized Methods

```ruby
service.total_memo_stats
# => { hits: 12, misses: 4, hit_rate: 0.75, methods: 3 }
```

Useful for dashboarding overall memoization effectiveness without iterating each method.

### Inspecting Cached Calls

Check whether a specific call is already cached, list the methods with live
caches, and measure per-method cache size without invoking the method.

```ruby
service = UserService.new
service.find(1)

service.memoized?(:find, 1) # => true
service.memoized?(:find, 2) # => false
service.cache_size(:find)   # => 1
service.memo_keys           # => [:find]
```

`memoized?` does not count as a hit or miss in `memo_stats`, so it is safe
to use in hot paths or test assertions.

### Surgical Invalidation

Drop a single cached call signature without clearing the entire method cache.

```ruby
service = UserService.new
service.find(1)
service.find(2)

service.forget_memo(:find, 1) # => true, only the (1) entry is removed
service.memoized?(:find, 1)   # => false
service.memoized?(:find, 2)   # => true
```

### Pruning Expired Entries

Caches with a TTL can evict expired entries eagerly without resetting stats.

```ruby
cache = Philiprehberger::Memo::Cache.new(ttl: 60)
cache.set(:a, 1)
sleep(61)
cache.set(:b, 2)

cache.prune_expired # => 1
cache.keys          # => [:b]
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
| `#memo_stats(method_name)` | Return `{ hits:, misses:, hit_rate: }` for a memoized method |
| `#total_memo_stats` | Aggregate `{ hits:, misses:, hit_rate:, methods: }` across all memoized methods |
| `#memoized?(method_name, *args, **kwargs)` | Return `true` when a non-expired cached value exists for the call |
| `#cache_size(method_name)` | Number of cached entries for a memoized method (`0` when absent) |
| `#memo_keys` | Names of methods that currently have caches on this instance |
| `#forget_memo(method_name, *args, **kwargs)` | Remove a single cached call signature; returns `true` when an entry is dropped |

### `Philiprehberger::Memo::Cache`

| Method | Description |
|--------|-------------|
| `.new(ttl: nil, max_size: nil)` | Create a cache with optional TTL (seconds) and max size |
| `#get(key)` | Fetch a cached value; returns `[found, value]` |
| `#set(key, value)` | Store a value in the cache |
| `#key?(key)` | `true` when a non-expired entry exists; does not affect stats |
| `#delete(key)` | Remove a specific entry; returns `true` when an entry was removed |
| `#keys` | All non-expired cache keys in LRU order |
| `#size` | Current number of cached entries |
| `#stats` | Return `{ hits:, misses:, hit_rate: }` |
| `#prune_expired` | Remove all expired entries and return the count removed |
| `#age(key)` | Seconds since the entry was stored (`nil` when missing or expired); no hit/miss impact |
| `#clear` | Remove all entries and reset stats |

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

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-memo)

🐛 [Report issues](https://github.com/philiprehberger/rb-memo/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-memo/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
