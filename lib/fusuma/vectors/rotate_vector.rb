module Fusuma
  module Vectors
    # vector data
    class RotateVector < BaseVector
      TYPE = 'rotate'.freeze
      EVENT = 'pinch'.freeze

      BASE_THERESHOLD = 0.5
      BASE_INTERVAL   = 0.1

      def initialize(finger, angle = 0)
        @finger = finger.to_i
        @angle = angle.to_f
      end

      attr_reader :finger, :angle

      def direction
        return 'clockwise' if angle > 0

        'counterclockwise'
      end

      def enough?
        enough_angle? && enough_interval?
      end

      def enough_angle?
        angle.abs > threshold
      end

      def enough_interval?
        return true if first_time?
        return true if (Time.now - self.class.last_time) > interval_time

        false
      end

      private

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

        def generate(events)
          return if events.first.gesture != EVENT
          return if Generator.prev_vector && Generator.prev_vector != self

          generator = Generator.new(events)
          angle = generator.avg_attrs(:rotate)
          Vectors::RotateVector.new(generator.finger, angle).tap do |v|
            return nil unless CommandExecutor.new(v).executable?
            return nil unless v.enough?

            Generator.prev_vector = self
          end
        end

        def touch_last_time
          @last_time = Time.now
        end
      end
    end
  end
end
