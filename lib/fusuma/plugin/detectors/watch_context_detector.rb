# frozen_string_literal: true

require_relative "detector"
require_relative "../events/records/context_record"

module Fusuma
  module Plugin
    module Detectors
      # Detects context changes from WatchContextInput and converts them to ContextRecord events
      class WatchContextDetector < Detector
        SOURCES = ["watch_context"].freeze

        #: () -> bool
        def watch?
          true
        end

        # Returns nil if the buffer is empty
        # Converts buffer events to ContextRecord
        # Parses "name:value" format and splits into name and value
        #: (Array[untyped]) -> Fusuma::Plugin::Events::Event?
        def detect(buffers)
          buffer = buffers.find { |b| b.type == "watch_context" }
          return nil if buffer.nil? || buffer.empty?

          event = buffer.events.first
          buffer.clear

          text = event.record.to_s
          name, value = parse_name_value(text)

          record = Events::Records::ContextRecord.new(name: name, value: value)
          create_event(record: record)
        end

        private

        #: (String) -> Array[untyped]
        def parse_name_value(text)
          name, *rest = text.split(":")
          value = rest.join(":")
          [name, value]
        end
      end
    end
  end
end
