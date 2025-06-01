# frozen_string_literal: true

require "./lib/fusuma/plugin/detectors/detector"
require "./lib/fusuma/plugin/buffers/buffer"
require "./lib/fusuma/plugin/events/records/index_record"

module Fusuma
  module Plugin
    module Detectors
      class DummyDetector < Detector
        # @param buffers [Array<Buffers::Buffer>]
        # @return [Event]
        #: (Array[untyped]) -> Fusuma::Plugin::Events::Event
        def detect(buffers)
          buffers.each do |buffer|
            next unless buffer.type == "dummy"

            record = Events::Records::IndexRecord.new(index: Config::Index.new(%w[dummy index]))
            return create_event(record: record)
          end
        end

        #: () -> Hash[untyped, untyped]
        def config_param_types
          {
            dummy: String
          }
        end
      end
    end
  end
end
