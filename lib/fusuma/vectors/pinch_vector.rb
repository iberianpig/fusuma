module Fusuma
  module Vectors
    # vector data
    class PinchVector < BaseVector
      TYPE = 'pinch'.freeze
      GESTURE = 'pinch'.freeze

      BASE_THERESHOLD = 0.1
      BASE_INTERVAL   = 0.1

      def initialize(finger, diameter = 0)
        @finger = finger.to_i
        @diameter = diameter.to_f
      end

      attr_reader :finger, :diameter

      def direction
        return 'in' if diameter > 1

        'out'
      end

      def enough?
        enough_diameter? && enough_interval?
      end

      private

      def enough_diameter?
        (diameter.abs - 1).abs > threshold
      end

      def enough_interval?
        return true if first_time?
        return true if (Time.now - self.class.last_time) > interval_time

        false
      end

      def first_time?
        !self.class.last_time
      end

      def threshold
        @threshold ||= BASE_THERESHOLD * Config.threshold(self)
      end

      def interval_time
        @interval_time ||= BASE_INTERVAL * Config.interval(self)
      end

      class << self
        attr_reader :last_time

        def generate(event_buffer:)
          return if event_buffer.gesture != GESTURE
          return if Generator.prev_vector && Generator.prev_vector != self

          diameter = calc_diameter(event_buffer)
          Vectors::PinchVector.new(event_buffer.finger, diameter).tap do |v|
            return nil unless CommandExecutor.new(v).executable?
            return nil unless v.enough?

            Generator.prev_vector = self
          end
        end

        private

        def calc_diameter(event_buffer)
          avg_zoom = event_buffer.avg_attrs(:zoom)
          first_zoom = event_buffer.events.first.body.zoom
          avg_zoom / first_zoom
        end
      end
    end
  end
end
