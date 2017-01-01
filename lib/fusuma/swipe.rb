module Fusuma
  # vector data
  class Swipe
    BASE_THERESHOLD = 20
    INTERVAL_TIME   = 0.5

    def initialize(x, y)
      @x = x
      @y = y
    end
    attr_reader :x, :y

    def direction
      return x > 0 ? 'right' : 'left' if x.abs > y.abs
      y > 0 ? 'down' : 'up'
    end

    def enough?
      MultiLogger.debug(x: x, y: y)
      enough_distance? && enough_interval? && self.class.touch_last_time
    end

    private

    def enough_distance?
      (x.abs > threshold) || (y.abs > threshold)
    end

    def enough_interval?
      return true if first_time?
      return true if (Time.now - self.class.last_time) > INTERVAL_TIME
      false
    end

    def first_time?
      self.class.last_time.nil?
    end

    def threshold
      @threshold ||= BASE_THERESHOLD * Config.threshold('swipe')
    end

    class << self
      attr_reader :last_time

      def touch_last_time
        @last_time = Time.now
      end
    end
  end
end
