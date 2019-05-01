module Fusuma
  module Plugin
    module Vectors
      class DummyVector < Vector
        def initialize(finger, direction)
          @finger = finger
          @direction = direction
        end
        attr_reader :finger, :direction
      end
    end
  end
end
