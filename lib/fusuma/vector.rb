require_relative './plugin_manager.rb'

module Fusuma
  # vector class
  module Vectors
    # Inherite this base
    class BaseVector < Plugin
      def initialize; end

      def direction; end

      def enough?; end

      class << self
        # @param event_buffer [EventBuffer]
        # @return [BaseVector]
        def generate; end

        def touch_last_time
          @last_time = Time.now
        end
      end
    end

    # Generate vector
    class Generator
      class << self
        attr_writer :prev_vector
        attr_reader :prev_vector
      end

      # @param event_buffer [EventBuffer]
      def initialize(event_buffer:)
        @event_buffer = event_buffer
      end

      # and generate vector
      # @return [vector]
      def run
        plugins.map do |klass|
          klass.generate(event_buffer: @event_buffer)
        end.compact.first
      end

      # vector plugins
      # @example
      #  [Fusuma::Vectors::RotateVector, Fusuma::Vectors::PinchVector,
      #   Fusuma::Vectors::SwipeVector]
      # @retrun [Array]
      def plugins
        BaseVector.plugins
      end
    end
  end
end
