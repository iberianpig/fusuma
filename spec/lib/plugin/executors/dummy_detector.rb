# frozen_string_literal: true

require './lib/fusuma/plugin/detectors/detector.rb'

module Fusuma
  module Plugin
    module Detectors
      class DummyDetector < Detector
        def initialize(finger, direction)
          @finger = finger
          @direction = direction
        end
        attr_reader :finger, :direction
      end
    end
  end
end
