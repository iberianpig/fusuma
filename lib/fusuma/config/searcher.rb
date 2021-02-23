# frozen_string_literal: true

# Index for searching value from config.yml
module Fusuma
  class Config
    # Search config.yml
    class Searcher
      def initialize
        @cache
      end

      # @param index [Index]
      # @param location [Hash]
      # @return [NilClass]
      # @return [Hash]
      # @return [Object]
      def search(index, location:)
        key = index.keys.first
        return location if key.nil?

        return nil if location.nil?

        return nil unless location.is_a?(Hash)

        next_index = Index.new(index.keys[1..-1])

        value = nil
        next_location_cadidates(location, key).find do |next_location|
          value = search(next_index, location: next_location)
        end
        value
      end

      # @param index [Index]
      # @param location [Hash]
      # @return [NilClass]
      # @return [Hash]
      # @return [Object]
      def search_with_cache(index, location:)
        cache([index.cache_key, Searcher.skip?, Searcher.fallback?]) do
          search(index, location: location)
        end
      end

      def cache(key)
        @cache ||= {}
        key = key.join(',') if key.is_a? Array
        if @cache.key?(key)
          @cache[key]
        else
          @cache[key] = block_given? ? yield : nil
        end
      end

      private

      # next locations' candidates sorted by priority
      #  1. look up location with key
      #  2. fallback to other key
      #  3. skip the key and go to child location
      def next_location_cadidates(location, key)
        [
          location[key.symbol],
          Searcher.fallback? && key.fallback && location[key.fallback],
          Searcher.skip? && key.skippable && location
        ].compact
      end

      class << self
        # @return [Hash]
        def conditions(&block)
          {
            nothing: -> { block.call },
            skip: -> { Config::Searcher.skip { block.call } },
            fallback: -> { Config::Searcher.fallback { block.call } },
            skip_fallback: -> { Config::Searcher.skip { Config::Searcher.fallback { block.call } } }
          }
        end

        # Execute block with specified conditions
        # @param conidtion [Symbol]
        # @return [Object]
        def with_condition(condition, &block)
          conditions(&block)[condition].call
        end

        # Execute block with all conditions
        # @return [Array<Symbol, Object>]
        def find_condition(&block)
          conditions(&block).find do |c, l|
            result = l.call
            return [c, result] if result

            nil
          end
        end

        def fallback?
          @fallback
        end

        def skip?
          @skip
        end

        # switch context for fallback
        def fallback(&block)
          @fallback = true
          result = block.call
          @fallback = false
          result
        end

        def skip(&block)
          @skip = true
          result = block.call
          @skip = false
          result
        end
      end
    end
  end
end
