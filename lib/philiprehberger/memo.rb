# frozen_string_literal: true

require_relative 'memo/version'
require_relative 'memo/cache'
require_relative 'memo/wrapper'

module Philiprehberger
  # Practical memoization with TTL, LRU eviction, and thread-safety
  module Memo
    class Error < StandardError; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level memo method
    module ClassMethods
      # Memoize a method by argument values
      #
      # @param method_name [Symbol] the method to memoize
      # @param ttl [Numeric, nil] time-to-live in seconds
      # @param max_size [Integer, nil] max cache entries (LRU eviction)
      def memo(method_name, ttl: nil, max_size: nil)
        Wrapper.apply(self, method_name, ttl: ttl, max_size: max_size)
      end
    end

    # Clear memoized cache for a specific method
    #
    # @param method_name [Symbol] the method name
    def clear_memo(method_name)
      cache = memo_cache_for(method_name)
      cache&.clear
    end

    # Return cache stats for a specific memoized method
    #
    # @param method_name [Symbol] the method name
    # @return [Hash, nil] :hits, :misses, :hit_rate or nil if not cached
    def memo_stats(method_name)
      cache = memo_cache_for(method_name)
      cache&.stats
    end

    # Check whether a call signature has been memoized for a method
    #
    # @param method_name [Symbol] the method name
    # @param args [Array] positional arguments used for the call
    # @param kwargs [Hash] keyword arguments used for the call
    # @return [Boolean] true if a non-expired cached value exists
    def memoized?(method_name, *args, **kwargs)
      cache = memo_cache_for(method_name)
      return false unless cache

      cache.key?([args, kwargs])
    end

    # Return the number of cached entries for a memoized method
    #
    # @param method_name [Symbol] the method name
    # @return [Integer] zero when the method has no cache yet
    def cache_size(method_name)
      cache = memo_cache_for(method_name)
      cache ? cache.size : 0
    end

    # Return the names of methods that currently have caches on this instance
    #
    # @return [Array<Symbol>] method names with initialized caches
    def memo_keys
      return [] unless instance_variable_defined?(:@_memo_caches)

      @_memo_caches.keys
    end

    # Remove a specific cached call signature without clearing the full cache
    #
    # @param method_name [Symbol] the method name
    # @param args [Array] positional arguments used for the call
    # @param kwargs [Hash] keyword arguments used for the call
    # @return [Boolean] true if an entry was removed, false otherwise
    def forget_memo(method_name, *args, **kwargs)
      cache = memo_cache_for(method_name)
      return false unless cache

      cache.delete([args, kwargs])
    end

    # Force the memoized method to recompute for the given call signature
    # and store the freshly-computed value in the cache. Subsequent calls
    # with the same arguments return the new value from cache.
    #
    # The existing cache entry for `[args, kwargs]` (if any) is dropped
    # before invoking the method, so the wrapper miss-path writes the new
    # value to the cache automatically.
    #
    # @param method_name [Symbol] the method name
    # @param args [Array] positional arguments to pass through
    # @param kwargs [Hash] keyword arguments to pass through
    # @raise [Philiprehberger::Memo::Error] when `method_name` is not memoized
    # @return [Object] the freshly-computed value
    def refresh_memo(method_name, *args, **kwargs)
      unless Wrapper.memoized_method?(self.class, method_name)
        raise Error, "method `#{method_name}` is not memoized"
      end

      forget_memo(method_name, *args, **kwargs)
      send(method_name, *args, **kwargs)
    end

    # Clear all memoized caches on this instance
    def clear_all_memos
      return unless instance_variable_defined?(:@_memo_caches)

      @_memo_caches.each_value(&:clear)
    end

    # Aggregate hit/miss stats across every memoized method on this instance.
    #
    # Returns a hash with totals plus a `methods` count. `hit_rate` is computed
    # over the combined hits and misses. Returns zeroes when no memoization
    # has occurred yet.
    #
    # @return [Hash] `{ hits:, misses:, hit_rate:, methods: }`
    def total_memo_stats
      return { hits: 0, misses: 0, hit_rate: 0.0, methods: 0 } unless instance_variable_defined?(:@_memo_caches)

      hits = 0
      misses = 0
      @_memo_caches.each_value do |cache|
        s = cache.stats
        hits += s[:hits]
        misses += s[:misses]
      end

      total = hits + misses
      {
        hits: hits,
        misses: misses,
        hit_rate: total.zero? ? 0.0 : hits.to_f / total,
        methods: @_memo_caches.size
      }
    end

    private

    def memo_cache_for(method_name)
      return unless instance_variable_defined?(:@_memo_caches)

      @_memo_caches[method_name]
    end
  end
end
