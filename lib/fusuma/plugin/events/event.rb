# frozen_string_literal: true

require_relative "../base"
require_relative "records/record"
require_relative "records/text_record"

module Fusuma
  module Plugin
    module Events
      # Event format
      class Event < Base
        attr_reader :time
        attr_accessor :tag #: String
        attr_accessor :record #: Records::Record

        # @param time [Time]
        # @param tag [Tag]
        # @param record [String, Record]
        #: (tag: String, record: String | Fusuma::Plugin::Events::Records::Record, ?time: Time | nil) -> void
        def initialize(tag:, record:, time: Time.now)
          super()
          @time = time
          @tag = tag
          @record = case record
          when Records::Record
            record
          when String
            Records::TextRecord.new(record)
          else
            raise ArgumentError,
              "@record should be String or Record: #{record.class}, #{record}"
          end
        end

        #: () -> String
        def inspect
          "tag: #{@tag}, record: #{@record}"
        end
      end
    end
  end
end
