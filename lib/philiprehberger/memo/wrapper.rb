# frozen_string_literal: true

module Philiprehberger
  module Memo
    # Wraps methods with memoization via define_method
    module Wrapper
      # Apply memoization to a method
      #
      # @param klass [Class] the target class
      # @param method_name [Symbol] the method to wrap
      # @param ttl [Numeric, nil] cache TTL
      # @param max_size [Integer, nil] max cache entries
      def self.apply(klass, method_name, ttl:, max_size:)
        original = klass.instance_method(method_name)
        opts = { ttl: ttl, max_size: max_size }

        define_memoized_method(klass, method_name, original, opts)
      end

      def self.define_memoized_method(klass, method_name, original, opts)
        klass.define_method(method_name) do |*args, **kwargs, &block|
          @_memo_caches ||= {}
          @_memo_caches[method_name] ||= Cache.new(ttl: opts[:ttl], max_size: opts[:max_size])
          found, value = @_memo_caches[method_name].get([args, kwargs])
          return value if found

          result = original.bind_call(self, *args, **kwargs, &block)
          @_memo_caches[method_name].set([args, kwargs], result)
          result
        end
      end
      private_class_method :define_memoized_method
    end
  end
end
