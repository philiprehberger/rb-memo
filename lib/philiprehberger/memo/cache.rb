# frozen_string_literal: true

module Philiprehberger
  module Memo
    # Per-method LRU cache with optional TTL
    class Cache
      # @param ttl [Numeric, nil] time-to-live in seconds
      # @param max_size [Integer, nil] maximum entries
      def initialize(ttl: nil, max_size: nil)
        @ttl = ttl
        @max_size = max_size
        @store = {}
        @mutex = Mutex.new
        @hits = 0
        @misses = 0
      end

      # Fetch a cached value
      #
      # @param key [Object] cache key
      # @return [Array(Boolean, Object)] [found, value]
      def get(key)
        @mutex.synchronize { fetch_entry(key) }
      end

      # Store a value in the cache
      #
      # @param key [Object] cache key
      # @param value [Object] value to store
      def set(key, value)
        @mutex.synchronize { store_entry(key, value) }
      end

      # Current number of cached entries
      #
      # @return [Integer]
      def size
        @mutex.synchronize { @store.size }
      end

      # Cache hit/miss statistics
      #
      # @return [Hash{Symbol => Numeric}] :hits, :misses, :hit_rate
      def stats
        @mutex.synchronize do
          total = @hits + @misses
          rate = total.zero? ? 0.0 : @hits.to_f / total
          { hits: @hits, misses: @misses, hit_rate: rate.round(4) }
        end
      end

      # Clear all entries and reset stats
      def clear
        @mutex.synchronize do
          @store.clear
          @hits = 0
          @misses = 0
        end
      end

      private

      def fetch_entry(key)
        unless @store.key?(key)
          @misses += 1
          return [false, nil]
        end

        entry = @store[key]
        if expired?(entry)
          @store.delete(key)
          @misses += 1
          return [false, nil]
        end
        refresh_lru(key)
        @hits += 1
        [true, entry[:value]]
      end

      def store_entry(key, value)
        evict_lru if @max_size && @store.size >= @max_size && !@store.key?(key)
        @store.delete(key)
        @store[key] = { value: value, time: Time.now }
      end

      def expired?(entry)
        @ttl && (Time.now - entry[:time]) > @ttl
      end

      def refresh_lru(key)
        entry = @store.delete(key)
        @store[key] = entry
      end

      def evict_lru
        @store.delete(@store.first[0])
      end
    end
  end
end
