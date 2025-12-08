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

      # Check whether a non-expired entry exists for a key
      #
      # @param key [Object] cache key
      # @return [Boolean]
      def key?(key)
        @mutex.synchronize do
          return false unless @store.key?(key)

          entry = @store[key]
          if expired?(entry)
            @store.delete(key)
            false
          else
            true
          end
        end
      end

      # Remove a specific entry from the cache
      #
      # @param key [Object] cache key
      # @return [Boolean] true if an entry was removed
      def delete(key)
        @mutex.synchronize { !@store.delete(key).nil? }
      end

      # Current number of cached entries
      #
      # @return [Integer]
      def size
        @mutex.synchronize { @store.size }
      end

      # All non-expired cache keys in insertion/LRU order
      #
      # @return [Array<Object>]
      def keys
        @mutex.synchronize do
          prune_expired_entries
          @store.keys
        end
      end

      # Remove all expired entries without clearing stats
      #
      # @return [Integer] number of entries removed
      def prune_expired
        @mutex.synchronize { prune_expired_entries }
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

      def prune_expired_entries
        return 0 unless @ttl

        removed = 0
        @store.delete_if do |_, entry|
          if expired?(entry)
            removed += 1
            true
          else
            false
          end
        end
        removed
      end
    end
  end
end
