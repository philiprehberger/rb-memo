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

    # Clear all memoized caches on this instance
    def clear_all_memos
      return unless instance_variable_defined?(:@_memo_caches)

      @_memo_caches.each_value(&:clear)
    end

    private

    def memo_cache_for(method_name)
      return unless instance_variable_defined?(:@_memo_caches)

      @_memo_caches[method_name]
    end
  end
end
