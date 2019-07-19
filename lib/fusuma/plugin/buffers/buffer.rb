# frozen_string_literal: true

module Fusuma
  module Plugin
    module Buffers
      # buffer events and output
      class Buffer < Base
        def initialize(detectors:)
          @detectors = detectors
          @events = Array.new(*args)
        end

        # @param event [Event]
        def push(event)
          @events.push(event)
        end

        # clear buffer
        def clear
          @events.clear
        end

        # @return [Event]
        def detect
          @detectors.reduce(@events) { |e, d| d.detect(e) }
        end
      end
    end
  end
end
