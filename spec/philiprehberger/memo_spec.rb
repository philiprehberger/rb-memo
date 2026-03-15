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

      def compute_negative # rubocop:disable Naming/PredicateMethod
        @call_count += 1
        false
      end
      memo :compute_negative

      def with_kwargs(val, key:)
        @call_count += 1
        val + key
      end
      memo :with_kwargs
    end
  end

  it 'has a version number' do
    expect(Philiprehberger::Memo::VERSION).not_to be_nil
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
      obj.returns_nil
      obj.returns_nil
      expect(obj.call_count).to eq(1)
    end

    it 'handles false return values' do
      obj = klass.new
      obj.compute_negative
      obj.compute_negative
      expect(obj.call_count).to eq(1)
    end

    it 'works with keyword arguments' do
      obj = klass.new
      expect(obj.with_kwargs(1, key: 2)).to eq(3)
      obj.with_kwargs(1, key: 2)
      expect(obj.call_count).to eq(1)
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
  end

  describe '#clear_memo' do
    it 'clears cache for a specific method' do
      obj = klass.new
      obj.expensive(5)
      obj.clear_memo(:expensive)
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
  end
end
