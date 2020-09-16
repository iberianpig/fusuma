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
      def search(index, location:)
        key = index.keys.first
        return location if key.nil?

        return nil if location.nil?

        return nil unless location.is_a?(Hash)

        next_index = Index.new(index.keys[1..-1])
        next_locations = [
          location[key.symbol],
          Searcher.use_fallback && key.fallback && location[key.fallback],
          Searcher.use_skip && key.skippable && location
        ].compact

        value = nil
        next_locations.find do |next_location|
          value = search(next_index, location: next_location)
        end
        value
      end

      def search_with_cache(index, location:)
        cache([index.cache_key, Searcher.use_skip, Searcher.use_fallback]) do
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

      class << self
        attr_reader :use_fallback, :use_skip

        # switch context for fallback
        def fallback(&block)
          @use_fallback = true
          result = block.call
          @use_fallback = false
          result
        end

        def skip(&block)
          @use_skip = true
          result = block.call
          @use_skip = false
          result
        end
      end
    end
  end
end
