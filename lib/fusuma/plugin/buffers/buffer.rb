# frozen_string_literal: true

require_relative "../base"

module Fusuma
  module Plugin
    module Buffers
      # buffer events and output
      class Buffer < Base
        #: (*nil | Array[untyped]) -> void
        def initialize(*args)
          super()
          @events = Array.new(*args)
        end

        attr_reader :events

        # @return [String]
        #: () -> String
        def type
          @type ||= self.class.name.underscore.split("/").last.gsub("_buffer", "")
        end

        # @param event [Event]
        #: (Fusuma::Plugin::Events::Event) -> Array[untyped]?
        def buffer(event)
          return if event&.tag != source

          @events.push(event)
        end

        # clear old events
        # @param current_time [Time]
        def clear_expired(current_time: Time.now)
        end

        # @return [TrueClass, FalseClass]
        #: () -> bool
        def empty?
          @events.empty?
        end

        # clear buffer
        #: () -> void
        def clear
          @events.clear
        end

        # Set source for tag from config.yml.
        # DEFAULT_SOURCE is defined in each plugins.
        #: () -> String
        def source
          @source ||= config_params(:source) || self.class.const_get(:DEFAULT_SOURCE)
        end
      end
    end
  end
end
