# frozen_string_literal: true

# Index for searching value from config.yml
module Fusuma
  class Config
    # Search config.yml
    class Searcher
      def initialize
        @cache = nil
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

      def search_with_context(index, location:, context:)
        return nil if location.nil?

        return search(index, location: location[0]) if context == {}

        new_location = location.find do |conf|
          search(index, location: conf) if conf[:context] == context
        end
        search(index, location: new_location)
      end

      # @param index [Index]
      # @param location [Hash]
      # @return [NilClass]
      # @return [Hash]
      # @return [Object]
      def search_with_cache(index, location:)
        cache([index.cache_key, Searcher.context, Searcher.skip?, Searcher.fallback?]) do
          search_with_context(index, location: location, context: Searcher.context)
        end
      end

      def cache(key)
        @cache ||= {}
        key = key.join(",") if key.is_a? Array
        if @cache.key?(key)
          @cache[key]
        else
          @cache[key] = block_given? ? yield : nil
        end
      end

      private

      # next locations' candidates sorted by priority
      #  1. look up location with key
      #  2. skip the key and go to child location
      def next_location_cadidates(location, key)
        [
          location[key.symbol],
          Searcher.skip? && key.skippable && location
        ].compact
      end

      class << self
        # @return [Hash]
        def conditions(&block)
          {
            nothing: -> { block.call },
            skip: -> { Config::Searcher.skip { block.call } }
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

        # Search with context from load_streamed Config
        # @param context [Hash]
        # @return [Object]
        def with_context(context, &block)
          @context = context || {}
          result = block.call
          @context = {}
          result
        end

        # Return a matching context from config
        # @params request_context [Hash]
        # @return [Hash]
        def find_context(request_context, &block)
          # Search in blocks in the following order.
          # 1. primary context(no context)
          # 2. complete match config[:context] == request_context
          # 3. partial match config[:context] =~ request_context
          return {} if with_context({}) { block.call }

          Config.instance.keymap.each do |config|
            next unless config[:context] == request_context
            return config[:context] if with_context(config[:context]) { block.call }
          end
          if request_context.keys.size > 1
            Config.instance.keymap.each do |config|
              next if config[:context].nil?

              next unless config[:context].all? { |k, v| request_context[k] == v }
              return config[:context] if with_context(config[:context]) { block.call }
            end
          end
        end

        attr_reader :context

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
