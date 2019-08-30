# frozen_string_literal: true

require './lib/fusuma/plugin/detectors/detector.rb'
require './lib/fusuma/plugin/buffers/buffer.rb'
require './lib/fusuma/plugin/events/records/index_record.rb'

module Fusuma
  module Plugin
    module Detectors
      class DummyDetector < Detector
        # @param buffers [Array<Buffers::Buffer>]
        # @return [Event]
        def detect(buffers)
          buffers.each do |buffer|
            next unless buffer.type == 'dummy'

            record = Events::Records::IndexRecord.new(index: Config::Index.new(%w[dummy index]))
            return create_event(record: record)
          end
        end
      end
    end
  end
end
