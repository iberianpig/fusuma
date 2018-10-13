module Fusuma
  # vector data
  class Rotate
    TYPE = 'rotate'.freeze

    BASE_THERESHOLD = 0.1
    BASE_INTERVAL   = 0.05

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
      MultiLogger.debug(angle: angle)
      enough_angle? && enough_interval?
    end

    private

    def enough_angle?
      angle.abs > threshold
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

      def touch_last_time
        @last_time = Time.now
      end
    end
  end
end
