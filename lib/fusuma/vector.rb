require_relative './plugin_manager.rb'

module Fusuma
  # vector class
  module Vectors
    class BaseVector < Plugin
      class << self
        def generate(events)
        end
      end
    end

    # GenerateVector
    class Generator
      class << self
        attr_writer :prev_vector
        attr_reader :prev_vector
      end

      # @param events [Array]
      def initialize(events)
        @events = events
      end

      # @return [vector]
      def generate
        BaseVector.plugins.map do |klass|
          klass.generate(@events)
        end.compact.first
        # case @events.first.gesture
        # when 'pinch'
        #   generate_pinch_or_rotate
        # end
      end

      def sum_attrs(attr)
        @events.map do |gesture_event|
          gesture_event.direction[attr]
        end.compact.inject(:+)
      end

      def avg_attrs(attr)
        sum_attrs(attr) / @events.length
      end

      # return [Integer]
      def finger
        @events.last.finger
      end

    end
  end
end
