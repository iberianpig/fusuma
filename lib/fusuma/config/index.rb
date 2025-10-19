# frozen_string_literal: true

# Index for searching value from config.yml
module Fusuma
  class Config
    # index for config.yml
    class Index
      #: (Array[untyped] | String | Symbol | Integer) -> void
      def initialize(keys)
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

      attr_reader :keys #: Array[Key]
      attr_reader :cache_key #: Symbol | Integer

      def to_s
        @keys.map(&:inspect)
      end

      def ==(other)
        return false unless other.is_a? Index

        cache_key == other.cache_key
      end

      # Keys in Index
      class Key
        attr_reader :symbol #: Symbol | Integer
        attr_reader :skippable #: bool

        #: (String | Integer | Symbol, ?skippable: bool) -> void
        def initialize(symbol_word, skippable: false)
          @symbol = case symbol_word
          when Integer, Symbol
            symbol_word
          else
            symbol_word.to_sym
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
      end
    end
  end
end
