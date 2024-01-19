# frozen_string_literal: true

# Index for searching value from config.yml
module Fusuma
  class Config
    # index for config.yml
    class Index
      def initialize(keys)
        @count = 0
        case keys
        when Array
          @keys = []
          @cache_key = keys.map do |key|
            key = Key.new(key) if !key.is_a? Key
            @keys << key
            key.symbol
          end.join(",").to_sym
        else
          key = Key.new(keys)
          @cache_key = key.symbol
          @keys = [key]
        end
      end

      def to_s
        @keys.map(&:inspect)
      end

      def ==(other)
        return false unless other.is_a? Index

        cache_key == other.cache_key
      end

      attr_reader :keys, :cache_key

      # Keys in Index
      class Key
        def initialize(symbol_word, skippable: false)
          @symbol = begin
            symbol_word.to_sym
          rescue
            symbol_word
          end

          @skippable = skippable
        end

        def to_s
          if @skippable
            "#{@symbol}(skippable)"
          else
            @symbol.to_s
          end
        end

        attr_reader :symbol, :skippable
      end
    end
  end
end
