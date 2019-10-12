# frozen_string_literal: true

require_relative '../base.rb'
require_relative '../events/event.rb'

module Fusuma
  module Plugin
    module Detectors
      # Inherite this base
      class Detector < Base
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
          Events::Event.new(time: Time.now, tag: tag, record: record)
        end

        def last_time
          @last_time ||= Time.now
        end

        def tag
          self.class.name.split('Detectors::').last.underscore
        end

        def type
          self.class.name.underscore.split('/').last.gsub('_detector', '')
        end
      end
    end
  end
end
