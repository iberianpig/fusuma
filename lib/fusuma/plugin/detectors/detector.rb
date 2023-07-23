# frozen_string_literal: true

require_relative "../base"
require_relative "../events/event"

module Fusuma
  module Plugin
    module Detectors
      # Inherite this base
      class Detector < Base
        def initialize(*args)
          super(*args)
          @tag = self.class.tag
          @type = self.class.type
        end

        attr_reader :tag
        attr_reader :type

        # @return [Array<String>]
        def sources
          @sources ||= self.class.const_get(:SOURCES)
        end

        # Always watch buffers and detect them or not
        # @return [TrueClass,FalseClass]
        def watch?
          false
        end

        # @param _buffers [Array<Buffer>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(_buffers)
          raise NotImplementedError, "override #{self.class.name}##{__method__}"

          # create_event(record:)
        end

        # @param record [Events::Records::Record]
        # @return [Events::Event]
        def create_event(record:)
          @last_time = Time.now
          Events::Event.new(time: @last_time, tag: tag, record: record)
        end

        def last_time
          @last_time ||= Time.now
        end

        def first_time?
          @last_time.nil?
        end

        class << self
          def tag
            name.split("Detectors::").last.underscore
          end

          def type(tag_name = tag)
            tag_name.gsub("_detector", "")
          end
        end
      end
    end
  end
end
