# frozen_string_literal: true

# Index for searching value from config.yml
module Fusuma
  class Config
    # Search config.yml
    class Searcher
      #: () -> void
      def initialize
        @cache = {}
      end

      # @param index [Index]
      # @param location [Hash]
      # @return [NilClass]
      # @return [Hash]
      # @return [Object]
      #: (Fusuma::Config::Index, location: untyped) -> untyped
      def search(index, location:)
        key = index.keys.first
        return location if key.nil?

        return nil if location.nil?

        return nil unless location.is_a?(Hash)

        next_index = Index.new(Array(index.keys[1..-1]))

        value = nil
        next_location_cadidates(location, key).find do |next_location|
          value = search(next_index, location: next_location)
        end
        value
      end

      #: (Fusuma::Config::Index, location: Array[untyped], context: Hash[untyped, untyped] | nil) -> untyped
      def search_with_context(index, location:, context:)
        return nil if location.nil?

        return search(index, location: location[0]) if context == {}

        value = nil
        location.find do |conf|
          value = search(index, location: conf) if conf[:context] == context
        end
        value
      end

      # @param index [Index]
      # @param location [Hash]
      # @return [NilClass]
      # @return [Hash]
      # @return [Object]
      #: (Fusuma::Config::Index, location: Array[untyped]) 
      def search_with_cache(index, location:)
        cache([index.cache_key, Searcher.context]) do
          search_with_context(index, location: location, context: Searcher.context)
        end
      end

      #: (Array[untyped] | String) -> untyped
      def cache(key)
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
      #: (Hash[untyped, untyped], Fusuma::Config::Index::Key) -> Array[untyped]
      def next_location_cadidates(location, key)
        [
          location[key.symbol],
          key.skippable && location
        ].compact
      end

      class << self
        attr_reader :context

        # Search with context from load_streamed Config
        # @param context [Hash]
        # @return [Object]
        #: (?Hash[untyped, untyped]) -> String?
        def with_context(context = {}, &block)
          before = @context
          @context = context
          block.call
        ensure # NOTE: ensure is called even if return in block
          @context = before
        end

        CONTEXT_SEARCH_ORDER = [:no_context, :complete_match_context, :partial_match_context]
        # Return a matching context from config
        # @params request_context [Hash]
        # @return [Hash]
        #: (Hash[untyped, untyped], ?Array[untyped]) -> Hash[untyped, untyped]?
        def find_context(request_context, fallbacks = CONTEXT_SEARCH_ORDER, &block)
          # Search in blocks in the following order.
          # 1. primary context(no context)
          # 2. complete match config[:context] == request_context
          # 3. partial match config[:context] =~ request_context
          # no_context?(&block) ||
          #   complete_match_context(request_context, &block) ||
          #   partial_match_context(request_context, &block)
          fallbacks.find do |method|
            result = send(method, request_context, &block)
            return result if result
          end
        end

        private

        # No context(primary context)
        # @return [Hash]
        # @return [NilClass]
        #: (Hash[untyped, untyped]) -> Hash[untyped, untyped]?
        def no_context(_request_context, &block)
          {} if with_context({}, &block)
        end

        # Complete match request context
        # @param request_context [Hash]
        # @return [Hash] matched context
        # @return [NilClass] if not matched
        def complete_match_context(request_context, &block)
          Config.instance.keymap.each do |config|
            next unless config[:context] == request_context
            return config[:context] if with_context(config[:context], &block)
          end
          nil
        end

        # One of multiple request contexts matched
        # @param request_context [Hash]
        # @return [Hash] matched context
        # @return [NilClass] if not matched
        def partial_match_context(request_context, &block)
          if request_context.keys.size > 1
            Config.instance.keymap.each do |config|
              next if config[:context].nil?

              next unless config[:context].all? { |k, v| request_context[k] == v }
              return config[:context] if with_context(config[:context], &block)
            end
            nil
          end
        end

        # Search context for plugin
        # If the plugin_defaults key is a complete match,
        # it is the default value for that plugin, so it is postponed.
        # This is because prioritize overwriting by other plugins.
        # The search order is as follows
        # 1. complete match config[:context].key?(:plugin_defaults)
        # 2. complete match config[:context] == request_context
        # @param request_context [Hash]
        # @return [Hash] matched context
        # @return [NilClass] if not matched
        #: (Hash[untyped, untyped]) -> Hash[untyped, untyped]?
        def plugin_default_context(request_context, &block)
          complete_match_context = nil
          Config.instance.keymap.each do |config|
            next unless config[:context]&.key?(:plugin_defaults)

            if config[:context][:plugin_defaults] == request_context[:plugin_defaults]
              complete_match_context = config[:context]
              next
            end

            return config[:context] if with_context(config[:context], &block)
          end
          if complete_match_context
            with_context(complete_match_context, &block)
            complete_match_context
          end
        end
      end
    end
  end
end
