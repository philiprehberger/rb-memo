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

        register_memoized_method(klass, method_name)
        define_memoized_method(klass, method_name, original, opts)
      end

      # Track which methods on a class have been wrapped with `memo`.
      # Walks the ancestor chain so subclasses inherit memoized markers
      # from their parents.
      #
      # @param klass [Class] the class to inspect
      # @param method_name [Symbol] the method to check
      # @return [Boolean]
      def self.memoized_method?(klass, method_name)
        klass.ancestors.any? do |ancestor|
          next false unless ancestor.is_a?(Class) || ancestor.is_a?(Module)
          next false unless ancestor.instance_variable_defined?(:@_memo_methods)

          ancestor.instance_variable_get(:@_memo_methods).include?(method_name)
        end
      end

      def self.register_memoized_method(klass, method_name)
        klass.instance_variable_set(:@_memo_methods, []) unless klass.instance_variable_defined?(:@_memo_methods)
        methods = klass.instance_variable_get(:@_memo_methods)
        methods << method_name unless methods.include?(method_name)
      end
      private_class_method :register_memoized_method

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
