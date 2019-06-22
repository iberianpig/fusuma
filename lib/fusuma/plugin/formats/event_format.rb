# frozen_string_literal: true

require_relative './format.rb'
require_relative './records/record.rb'

module Fusuma
  module Plugin
    module Formats
      # Event format
      class Event < Format
        attr_reader :time
        attr_accessor :tag, :record

        # @param time [Time]
        # @param tag [Tag]
        # @param record [String, RecordFormat]
        def initialize(time: Time.now, tag:, record:)
          @time = time
          @tag = tag
          @record = case record
                    when Records::Record
                      record
                    when String
                      Records::TextRecord.new(record)
                    else
                      raise ArgumentError,
                            'record should be String or RecordFormat'
                    end
        end

        def inspect
          "time: #{time}, tag: #{tag}, record: #{record}"
        end
      end
    end
  end
end
