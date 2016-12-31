module Fusuma
  # manage actions
  class Swipe
    BASE_THERESHOLD = 20

    def initialize(x, y)
      @x = x
      @y = y
    end
    attr_reader :x, :y

    def direction
      return x > 0 ? 'right' : 'left' if x.abs > y.abs
      y > 0 ? 'down' : 'up'
    end

    def enough_distance?
      MultiLogger.debug(x: x, y: y)
      (x.abs > threshold) || (y.abs > threshold)
    end

    def threshold
      @threshold ||= BASE_THERESHOLD * config.threshold('swipe')
    end

    def config
      @config ||= Config.new
    end
  end
end
