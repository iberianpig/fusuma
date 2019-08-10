# frozen_string_literal: true

require './lib/fusuma/plugin/detectors/detector.rb'
require './lib/fusuma/plugin/buffers/buffer.rb'

module Fusuma
  module Plugin
    module Detectors
      class DummyDetector < Detector
        # @param buffers [Array<Buffers::Buffer>]
        # @return [Event]
        def detect(buffers)
          buffers.each do |buffer|
            next unless buffer.type == 'dummy'

            return create_event(record: 'dummy_vector')
          end
        end
      end
    end
  end
end
