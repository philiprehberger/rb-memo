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

      # Clear all entries
      def clear
        @mutex.synchronize { @store.clear }
      end

      private

      def fetch_entry(key)
        return [false, nil] unless @store.key?(key)

        entry = @store[key]
        if expired?(entry)
          @store.delete(key)
          return [false, nil]
        end
        refresh_lru(key)
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
