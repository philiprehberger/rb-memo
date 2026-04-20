# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Memo do
  let(:klass) do
    Class.new do
      include Philiprehberger::Memo

      attr_reader :call_count

      def initialize
        @call_count = 0
      end

      def expensive(arg)
        @call_count += 1
        arg * 2
      end
      memo :expensive

      def returns_nil
        @call_count += 1
        nil
      end
      memo :returns_nil

      def compute_negative
        @call_count += 1
        false
      end
      memo :compute_negative

      def with_kwargs(val, key:)
        @call_count += 1
        val + key
      end
      memo :with_kwargs

      def no_args
        @call_count += 1
        'constant'
      end
      memo :no_args

      def multi_args(a, b, c)
        @call_count += 1
        a + b + c
      end
      memo :multi_args
    end
  end

  it 'has a version number' do
    expect(Philiprehberger::Memo::VERSION).not_to be_nil
  end

  it 'version is a valid semver string' do
    expect(Philiprehberger::Memo::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe 'basic memoization' do
    it 'caches method results' do
      obj = klass.new
      obj.expensive(5)
      obj.expensive(5)
      expect(obj.call_count).to eq(1)
    end

    it 'returns the correct cached value' do
      obj = klass.new
      expect(obj.expensive(5)).to eq(10)
      expect(obj.expensive(5)).to eq(10)
    end

    it 'caches separately by arguments' do
      obj = klass.new
      obj.expensive(5)
      obj.expensive(10)
      expect(obj.call_count).to eq(2)
    end

    it 'handles nil return values' do
      obj = klass.new
      result1 = obj.returns_nil
      result2 = obj.returns_nil
      expect(result1).to be_nil
      expect(result2).to be_nil
      expect(obj.call_count).to eq(1)
    end

    it 'handles false return values' do
      obj = klass.new
      result1 = obj.compute_negative
      result2 = obj.compute_negative
      expect(result1).to be false
      expect(result2).to be false
      expect(obj.call_count).to eq(1)
    end

    it 'works with keyword arguments' do
      obj = klass.new
      expect(obj.with_kwargs(1, key: 2)).to eq(3)
      obj.with_kwargs(1, key: 2)
      expect(obj.call_count).to eq(1)
    end

    it 'differentiates keyword argument values' do
      obj = klass.new
      expect(obj.with_kwargs(1, key: 2)).to eq(3)
      expect(obj.with_kwargs(1, key: 5)).to eq(6)
      expect(obj.call_count).to eq(2)
    end

    it 'works with no arguments' do
      obj = klass.new
      expect(obj.no_args).to eq('constant')
      obj.no_args
      expect(obj.call_count).to eq(1)
    end

    it 'works with multiple positional arguments' do
      obj = klass.new
      expect(obj.multi_args(1, 2, 3)).to eq(6)
      obj.multi_args(1, 2, 3)
      expect(obj.call_count).to eq(1)
    end

    it 'differentiates multiple positional arguments' do
      obj = klass.new
      obj.multi_args(1, 2, 3)
      obj.multi_args(4, 5, 6)
      expect(obj.call_count).to eq(2)
    end
  end

  describe 'per-instance caching' do
    it 'keeps separate caches per instance' do
      a = klass.new
      b = klass.new
      a.expensive(5)
      b.expensive(5)
      expect(a.call_count).to eq(1)
      expect(b.call_count).to eq(1)
    end

    it 'does not share cached values between instances' do
      a = klass.new
      b = klass.new
      a.expensive(5)
      expect(b.expensive(5)).to eq(10)
      expect(b.call_count).to eq(1)
    end

    it 'clearing one instance does not affect another' do
      a = klass.new
      b = klass.new
      a.expensive(5)
      b.expensive(5)
      a.clear_memo(:expensive)
      a.expensive(5)
      expect(a.call_count).to eq(2)
      expect(b.call_count).to eq(1)
    end
  end

  describe 'TTL' do
    let(:ttl_klass) do
      Class.new do
        include Philiprehberger::Memo

        attr_reader :call_count

        def initialize
          @call_count = 0
        end

        def timed(arg)
          @call_count += 1
          arg
        end
        memo :timed, ttl: 0.5
      end
    end

    it 'expires after TTL' do
      obj = ttl_klass.new
      obj.timed(1)
      sleep 0.6
      obj.timed(1)
      expect(obj.call_count).to eq(2)
    end

    it 'serves cached value before TTL expires' do
      obj = ttl_klass.new
      obj.timed(1)
      obj.timed(1)
      expect(obj.call_count).to eq(1)
    end

    it 'expires each key independently' do
      obj = ttl_klass.new
      obj.timed(1)
      sleep 0.3
      obj.timed(2)
      sleep 0.3
      # key 1 expired (0.6s elapsed), key 2 still valid (0.3s elapsed)
      obj.timed(1)
      obj.timed(2)
      expect(obj.call_count).to eq(3)
    end
  end

  describe 'LRU eviction' do
    let(:lru_klass) do
      Class.new do
        include Philiprehberger::Memo

        attr_reader :call_count

        def initialize
          @call_count = 0
        end

        def limited(arg)
          @call_count += 1
          arg
        end
        memo :limited, max_size: 2
      end
    end

    it 'evicts oldest entry when max_size exceeded' do
      obj = lru_klass.new
      obj.limited(1)
      obj.limited(2)
      obj.limited(3)
      obj.limited(1) # was evicted, should recompute
      expect(obj.call_count).to eq(4)
    end

    it 'does not evict recently accessed entries' do
      obj = lru_klass.new
      obj.limited(1)
      obj.limited(2)
      obj.limited(1) # access 1 again, making 2 the LRU
      obj.limited(3) # evicts 2, not 1
      obj.limited(1) # still cached
      expect(obj.call_count).to eq(3)
    end

    it 'keeps max_size entries at most' do
      obj = lru_klass.new
      obj.limited(1)
      obj.limited(2)
      obj.limited(3)
      # entry 1 was evicted
      obj.limited(1) # recompute
      obj.limited(2) # recompute (was evicted when 1 re-entered)
      expect(obj.call_count).to eq(5)
    end

    it 'does not evict when updating existing key' do
      obj = lru_klass.new
      obj.limited(1)
      obj.limited(2)
      obj.limited(1) # existing key, no eviction needed
      obj.limited(2) # existing key, no eviction needed
      expect(obj.call_count).to eq(2)
    end
  end

  describe '#clear_memo' do
    it 'clears cache for a specific method' do
      obj = klass.new
      obj.expensive(5)
      obj.clear_memo(:expensive)
      obj.expensive(5)
      expect(obj.call_count).to eq(2)
    end

    it 'does not clear cache for other methods' do
      obj = klass.new
      obj.expensive(5)
      obj.no_args
      obj.clear_memo(:expensive)
      obj.no_args
      expect(obj.call_count).to eq(2)
    end

    it 'is safe to call on un-memoized method' do
      obj = klass.new
      expect { obj.clear_memo(:nonexistent) }.not_to raise_error
    end

    it 'allows re-memoization after clear' do
      obj = klass.new
      obj.expensive(5)
      obj.clear_memo(:expensive)
      obj.expensive(5)
      obj.expensive(5)
      expect(obj.call_count).to eq(2)
    end
  end

  describe '#clear_all_memos' do
    it 'clears all caches' do
      obj = klass.new
      obj.expensive(5)
      obj.returns_nil
      obj.clear_all_memos
      obj.expensive(5)
      obj.returns_nil
      expect(obj.call_count).to eq(4)
    end

    it 'is safe to call before any memoization' do
      obj = klass.new
      expect { obj.clear_all_memos }.not_to raise_error
    end

    it 'allows re-memoization after clearing all' do
      obj = klass.new
      obj.expensive(5)
      obj.clear_all_memos
      obj.expensive(5)
      obj.expensive(5)
      expect(obj.call_count).to eq(2)
    end
  end

  describe 'Cache class directly' do
    it 'returns not-found for missing keys' do
      cache = Philiprehberger::Memo::Cache.new
      found, value = cache.get(:missing)
      expect(found).to be false
      expect(value).to be_nil
    end

    it 'stores and retrieves values' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:key, 'hello')
      found, value = cache.get(:key)
      expect(found).to be true
      expect(value).to eq('hello')
    end

    it 'clears all entries' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.set(:b, 2)
      cache.clear
      found_a, = cache.get(:a)
      found_b, = cache.get(:b)
      expect(found_a).to be false
      expect(found_b).to be false
    end
  end

  describe 'Cache#size' do
    it 'returns current number of entries' do
      cache = Philiprehberger::Memo::Cache.new
      expect(cache.size).to eq(0)
      cache.set(:a, 1)
      cache.set(:b, 2)
      expect(cache.size).to eq(2)
    end

    it 'decreases after clear' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.clear
      expect(cache.size).to eq(0)
    end
  end

  describe 'Cache#stats' do
    it 'tracks hits and misses' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.get(:a)
      cache.get(:a)
      cache.get(:b)
      stats = cache.stats
      expect(stats[:hits]).to eq(2)
      expect(stats[:misses]).to eq(1)
      expect(stats[:hit_rate]).to be_within(0.001).of(0.6667)
    end

    it 'returns zero hit_rate when no lookups' do
      cache = Philiprehberger::Memo::Cache.new
      expect(cache.stats[:hit_rate]).to eq(0.0)
    end

    it 'resets stats on clear' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.get(:a)
      cache.clear
      expect(cache.stats).to eq({ hits: 0, misses: 0, hit_rate: 0.0 })
    end

    it 'counts expired lookups as misses' do
      cache = Philiprehberger::Memo::Cache.new(ttl: 0.01)
      cache.set(:a, 1)
      sleep(0.02)
      cache.get(:a)
      expect(cache.stats[:misses]).to eq(1)
      expect(cache.stats[:hits]).to eq(0)
    end
  end

  describe '#memo_stats' do
    it 'returns stats for a memoized method' do
      obj = klass.new
      obj.expensive(1)
      obj.expensive(1)
      obj.expensive(2)
      stats = obj.memo_stats(:expensive)
      expect(stats[:hits]).to eq(1)
      expect(stats[:misses]).to eq(2)
    end

    it 'returns nil for un-memoized method' do
      obj = klass.new
      expect(obj.memo_stats(:nonexistent)).to be_nil
    end
  end

  describe '#memoized?' do
    it 'returns true once a call has been cached' do
      obj = klass.new
      obj.expensive(5)
      expect(obj.memoized?(:expensive, 5)).to be true
    end

    it 'returns false before the method has been called' do
      obj = klass.new
      expect(obj.memoized?(:expensive, 5)).to be false
    end

    it 'distinguishes different positional arguments' do
      obj = klass.new
      obj.expensive(5)
      expect(obj.memoized?(:expensive, 5)).to be true
      expect(obj.memoized?(:expensive, 6)).to be false
    end

    it 'distinguishes keyword arguments' do
      obj = klass.new
      obj.with_kwargs(1, key: 2)
      expect(obj.memoized?(:with_kwargs, 1, key: 2)).to be true
      expect(obj.memoized?(:with_kwargs, 1, key: 3)).to be false
    end

    it 'does not count as a hit or miss' do
      obj = klass.new
      obj.expensive(5)
      before = obj.memo_stats(:expensive).dup
      obj.memoized?(:expensive, 5)
      obj.memoized?(:expensive, 99)
      expect(obj.memo_stats(:expensive)).to eq(before)
    end

    it 'returns false for un-memoized methods' do
      obj = klass.new
      expect(obj.memoized?(:nonexistent)).to be false
    end

    it 'returns false after a TTL expiry' do
      ttl_klass = Class.new do
        include Philiprehberger::Memo

        def timed(arg) = arg
        memo :timed, ttl: 0.05
      end

      obj = ttl_klass.new
      obj.timed(1)
      expect(obj.memoized?(:timed, 1)).to be true
      sleep(0.1)
      expect(obj.memoized?(:timed, 1)).to be false
    end
  end

  describe '#cache_size' do
    it 'returns zero when the method has never been called' do
      obj = klass.new
      expect(obj.cache_size(:expensive)).to eq(0)
    end

    it 'returns the number of distinct cached calls' do
      obj = klass.new
      obj.expensive(1)
      obj.expensive(2)
      obj.expensive(3)
      expect(obj.cache_size(:expensive)).to eq(3)
    end

    it 'does not grow when identical calls are repeated' do
      obj = klass.new
      3.times { obj.expensive(1) }
      expect(obj.cache_size(:expensive)).to eq(1)
    end

    it 'returns zero for un-memoized methods' do
      obj = klass.new
      expect(obj.cache_size(:nonexistent)).to eq(0)
    end

    it 'respects max_size bounds' do
      lru_klass = Class.new do
        include Philiprehberger::Memo

        def limited(arg) = arg
        memo :limited, max_size: 2
      end

      obj = lru_klass.new
      obj.limited(1)
      obj.limited(2)
      obj.limited(3)
      expect(obj.cache_size(:limited)).to eq(2)
    end
  end

  describe '#memo_keys' do
    it 'returns an empty array before any method is called' do
      obj = klass.new
      expect(obj.memo_keys).to eq([])
    end

    it 'lists methods that have been invoked' do
      obj = klass.new
      obj.expensive(1)
      obj.no_args
      expect(obj.memo_keys).to contain_exactly(:expensive, :no_args)
    end

    it 'does not include methods that have not been called' do
      obj = klass.new
      obj.expensive(1)
      expect(obj.memo_keys).not_to include(:no_args)
    end
  end

  describe '#forget_memo' do
    it 'removes a single cached entry without touching others' do
      obj = klass.new
      obj.expensive(1)
      obj.expensive(2)
      expect(obj.forget_memo(:expensive, 1)).to be true
      expect(obj.memoized?(:expensive, 1)).to be false
      expect(obj.memoized?(:expensive, 2)).to be true
    end

    it 'returns false when the entry does not exist' do
      obj = klass.new
      obj.expensive(1)
      expect(obj.forget_memo(:expensive, 99)).to be false
    end

    it 'returns false for an un-memoized method' do
      obj = klass.new
      expect(obj.forget_memo(:nonexistent, 1)).to be false
    end

    it 'triggers recomputation on the next call' do
      obj = klass.new
      obj.expensive(1)
      obj.forget_memo(:expensive, 1)
      obj.expensive(1)
      expect(obj.call_count).to eq(2)
    end

    it 'handles keyword argument signatures' do
      obj = klass.new
      obj.with_kwargs(1, key: 2)
      expect(obj.forget_memo(:with_kwargs, 1, key: 2)).to be true
      expect(obj.memoized?(:with_kwargs, 1, key: 2)).to be false
    end
  end

  describe 'Cache#key?' do
    it 'returns false for unknown keys' do
      cache = Philiprehberger::Memo::Cache.new
      expect(cache.key?(:missing)).to be false
    end

    it 'returns true for set keys' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      expect(cache.key?(:a)).to be true
    end

    it 'returns false once the entry has expired' do
      cache = Philiprehberger::Memo::Cache.new(ttl: 0.05)
      cache.set(:a, 1)
      sleep(0.1)
      expect(cache.key?(:a)).to be false
    end

    it 'does not increment hit or miss counters' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.key?(:a)
      cache.key?(:missing)
      expect(cache.stats).to eq({ hits: 0, misses: 0, hit_rate: 0.0 })
    end
  end

  describe 'Cache#delete' do
    it 'returns true when an entry is removed' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      expect(cache.delete(:a)).to be true
    end

    it 'returns false when nothing is removed' do
      cache = Philiprehberger::Memo::Cache.new
      expect(cache.delete(:missing)).to be false
    end

    it 'decreases the cache size' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.set(:b, 2)
      cache.delete(:a)
      expect(cache.size).to eq(1)
    end
  end

  describe 'Cache#keys' do
    it 'returns all stored keys in LRU order' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.set(:b, 2)
      cache.set(:c, 3)
      expect(cache.keys).to eq(%i[a b c])
    end

    it 'returns an empty array for a new cache' do
      cache = Philiprehberger::Memo::Cache.new
      expect(cache.keys).to eq([])
    end

    it 'omits expired entries' do
      cache = Philiprehberger::Memo::Cache.new(ttl: 0.05)
      cache.set(:a, 1)
      sleep(0.1)
      cache.set(:b, 2)
      expect(cache.keys).to eq([:b])
    end
  end

  describe 'Cache#prune_expired' do
    it 'removes expired entries and returns the count' do
      cache = Philiprehberger::Memo::Cache.new(ttl: 0.05)
      cache.set(:a, 1)
      cache.set(:b, 2)
      sleep(0.1)
      cache.set(:c, 3)
      removed = cache.prune_expired
      expect(removed).to eq(2)
      expect(cache.size).to eq(1)
    end

    it 'returns zero when no TTL is configured' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      expect(cache.prune_expired).to eq(0)
      expect(cache.size).to eq(1)
    end

    it 'returns zero when nothing is expired yet' do
      cache = Philiprehberger::Memo::Cache.new(ttl: 5)
      cache.set(:a, 1)
      expect(cache.prune_expired).to eq(0)
    end
  end

  describe 'Cache#age' do
    it 'returns nil for missing keys' do
      cache = Philiprehberger::Memo::Cache.new
      expect(cache.age(:missing)).to be_nil
    end

    it 'returns the seconds since the entry was stored' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      sleep(0.05)
      age = cache.age(:a)
      expect(age).to be_a(Float)
      expect(age).to be >= 0.04
    end

    it 'returns nil for expired entries' do
      cache = Philiprehberger::Memo::Cache.new(ttl: 0.02)
      cache.set(:a, 1)
      sleep(0.05)
      expect(cache.age(:a)).to be_nil
    end

    it 'does not record a hit or miss' do
      cache = Philiprehberger::Memo::Cache.new
      cache.set(:a, 1)
      cache.age(:a)
      cache.age(:missing)
      stats = cache.stats
      expect(stats[:hits]).to eq(0)
      expect(stats[:misses]).to eq(0)
    end
  end
end
