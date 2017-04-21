module Fusuma
  # vector data
  class Pinch
    BASE_THERESHOLD = 0.3

    def initialize(diameter)
      @diameter = diameter.to_f
    end

    attr_reader :diameter

    def direction
      return 'in' if diameter > 0
      'out'
    end

    def enough?
      MultiLogger.debug(diameter: diameter)
      enough_diameter? && enough_interval? && self.class.touch_last_time
    end

    private

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

    def threshold
      @threshold ||= BASE_THERESHOLD * Config.threshold('pinch')
    end

    def interval_time
      @interval_time ||= Config.interval('pinch')
    end

    class << self
      attr_reader :last_time

      def touch_last_time
        @last_time = Time.now
      end
    end
  end
end
