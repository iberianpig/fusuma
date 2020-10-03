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
