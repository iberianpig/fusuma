# frozen_string_literal: true

# Index for searching value from config.yml
module Fusuma
  class Config
    # index for config.yml
    class Index
      def initialize(keys)
        @keys = case keys
                when Array
                  keys.map do |key|
                    if key.is_a? Key
                      key
                    else
                      Key.new(key)
                    end
                  end
                else
                  [Key.new(keys)]
                end
      end

      def to_s
        @keys.map(&:to_s)
      end

      attr_reader :keys

      def cache_key
        case @keys
        when Array
          @keys.map(&:symbol).join(',')
        when Key
          @keys.symbol
        else
          raise 'invalid keys'
        end
      end

      # Keys in Index
      class Key
        def initialize(symbol_word, skippable: false, fallback: nil)
          @symbol = begin
            symbol_word.to_sym
          rescue StandardError
            symbol_word
          end

          @skippable = skippable

          @fallback = begin
            fallback.to_sym
          rescue StandardError
            fallback
          end
        end

        def inspect
          skip_marker = @skippable && Searcher.skip? ? '(skip)' : ''
          fallback_marker = @fallback && Searcher.fallback? ? '(fallback)' : ''
          "#{@symbol}#{skip_marker}#{fallback_marker}"
        end

        attr_reader :symbol, :skippable, :fallback
      end
    end
  end
end
