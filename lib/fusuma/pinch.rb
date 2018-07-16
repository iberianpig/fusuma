module Fusuma
  # vector data
  class Pinch
    BASE_THERESHOLD = 0.3
    BASE_INTERVAL   = 0.05
    BASE_SWIPE_THERESHOLD = 20
    BASE_SWIPE_INTERVAL   = 0.5

    def initialize(x,y,diameter)
      @diameter = diameter.to_f
      @x = x
      @y = y
    end

    attr_reader :diameter

    def direction
      return x > 0 ? 'right' : 'left' if enough_distance? && x.abs > y.abs
      y > 0 ? 'down' : 'up' if enough_distance?
      'in' if diameter > 0
      'out'
    end

    def enough?
      MultiLogger.debug(x: x, y: y)
      MultiLogger.debug(edist: enough_distance?,etime: enough_interval?)
      MultiLogger.debug(diameter: diameter)
      (enough_diameter? && enough_interval? && self.class.touch_last_time) || (enough_distance? && enough_interval? && self.class.touch_last_time)
    end
    
    private

    def enough_distance?
      (x.abs > dist_threshold) || (y.abs > dist_threshold)
    end

    def enough_diameter?
      diameter.abs > threshold
    end

    def enough_interval?
      return true if first_time?
      return true if (Time.now - self.class.last_time) > interval_time
      false
    end

    def first_time?
      self.class.last_time.nil?
    end


    def dist_threshold
      @dist_threshold ||= BASE_SWIPE_THERESHOLD * Config.threshold('swipe')
    end

    def dist_interval_time
      @dist_interval_time ||= BASE_SWIPE_INTERVAL * Config.interval('swipe')
    end


    def threshold
      @threshold ||= BASE_THERESHOLD * Config.threshold('pinch')
    end

    def interval_time
      @interval_time ||= BASE_INTERVAL * Config.interval('pinch')
    end

    class << self
      attr_reader :last_time

      def touch_last_time
        @last_time = Time.now
      end
    end
  end
end
