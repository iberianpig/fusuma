module Fusuma
  # vector data
  class Pinch
    TYPE = 'pinch'.freeze

    BASE_THERESHOLD = 0.3
    BASE_INTERVAL   = 0.05

    def initialize(diameter)
      @diameter = diameter.to_f
    end

    attr_reader :diameter

    def direction
      return 'in' if diameter > 0
      'out'
    end

    def enough?(trigger)
      MultiLogger.debug(diameter: diameter)
      enough_diameter?(trigger) && enough_interval?(trigger) &&
        self.class.touch_last_time
    end

    private

    def enough_diameter?(trigger)
      diameter.abs > threshold(trigger)
    end

    def enough_interval?(trigger)
      return true if first_time?
      return true if (Time.now - self.class.last_time) > interval_time(trigger)
      false
    end

    def first_time?
      self.class.last_time.nil?
    end

    def threshold(trigger)
      @threshold ||= BASE_THERESHOLD * Config.threshold('pinch', trigger)
    end

    def interval_time(trigger)
      @interval_time ||= BASE_INTERVAL * Config.interval('pinch', trigger)
    end

    class << self
      attr_reader :last_time

      def touch_last_time
        @last_time = Time.now
      end
    end
  end
end
