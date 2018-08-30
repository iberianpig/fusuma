module Fusuma
  # vector data
  class Swipe
    TYPE = 'swipe'.freeze

    BASE_THERESHOLD = 20
    BASE_INTERVAL   = 0.5

    def initialize(move_x, move_y)
      @x = move_x
      @y = move_y
    end
    attr_reader :x, :y

    def direction
      return x > 0 ? 'right' : 'left' if x.abs > y.abs
      y > 0 ? 'down' : 'up'
    end

    def enough?(trigger)
      MultiLogger.debug(x: x, y: y)
      enough_distance?(trigger) && enough_interval?(trigger) &&
        self.class.touch_last_time
    end

    private

    def enough_distance?(trigger)
      threshold = threshold(trigger)
      (x.abs > threshold) || (y.abs > threshold)
    end

    def enough_interval?(trigger)
      return true if first_time?
      return true if (Time.now - self.class.last_time) > interval_time(trigger)
      false
    end

    def first_time?
      !self.class.last_time
    end

    def threshold(trigger)
      @threshold ||= BASE_THERESHOLD * Config.threshold(trigger)
    end

    def interval_time(trigger)
      @interval_time ||= BASE_INTERVAL * Config.interval(trigger)
    end

    class << self
      attr_reader :last_time

      def touch_last_time
        @last_time = Time.now
      end
    end
  end
end
