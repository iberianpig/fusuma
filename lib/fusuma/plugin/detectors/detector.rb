# frozen_string_literal: true

require_relative "../base"
require_relative "../events/event"

module Fusuma
  module Plugin
    module Detectors
      # Inherite this base
      class Detector < Base
        def self.type(tag_name)
          tag_name.gsub("_detector", "")
        end

        #: (*nil) -> void
        def initialize(*args)
          super
          @tag = self.class.name.split("Detectors::").last.underscore
          @type = self.class.type(@tag)
        end

        attr_reader :tag #: String
        attr_reader :type #: String

        # @return [Array<String>]
        #: () -> Array[String]
        def sources
          @sources ||= self.class.const_get(:SOURCES)
        end

        # Always watch buffers and detect them or not
        # @return [TrueClass,FalseClass]
        #: () -> bool
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
        #: (record: Fusuma::Plugin::Events::Records::IndexRecord) -> Fusuma::Plugin::Events::Event
        def create_event(record:)
          @last_time = Time.now
          Events::Event.new(time: @last_time, tag: @tag, record: record)
        end

        #: () -> Time
        def last_time
          @last_time ||= Time.now
        end

        #: () -> bool
        def first_time?
          @last_time.nil?
        end
      end
    end
  end
end
