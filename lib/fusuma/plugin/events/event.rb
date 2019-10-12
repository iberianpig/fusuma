# frozen_string_literal: true

require_relative '../base.rb'
require_relative './records/record.rb'
require_relative './records/text_record.rb'

module Fusuma
  module Plugin
    module Events
      # Event format
      class Event < Base
        attr_reader :time
        attr_accessor :tag, :record

        # @param time [Time]
        # @param tag [Tag]
        # @param record [String, Record]
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
                            '@record should be String or Record'
                    end
        end

        def inspect
          "time: #{time}, tag: #{tag}, record: #{record}"
        end
      end
    end
  end
end
