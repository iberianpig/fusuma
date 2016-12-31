module Fusuma
  # manage actions
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

    def enough_diameter?
      MultiLogger.debug(diameter: diameter)
      diameter.abs > threshold
    end

    def threshold
      @threshold ||= BASE_THERESHOLD * Config.threshold('pinch')
    end
  end
end
