# frozen_string_literal: true

require_relative "../base"

module Fusuma
  module Plugin
    module Parsers
      # Parser change record and tag in event
      # Inherite this base class
      class Parser < Base
        # Parse Event and convert Record and Tag
        # if `#parse_record` return nil, this method will return original event
        # @param event [Event]
        # @return [Event]
        #: (Fusuma::Plugin::Events::Event) -> Fusuma::Plugin::Events::Event
        def parse(event)
          return event if event.tag != source

          new_record = parse_record(event.record)
          return event if new_record.nil?

          event.record = new_record
          event.tag = tag
          event
        end

        # Set source for tag from config.yml.
        # DEFAULT_SOURCE is defined in each Parser plugins.
        #: () -> String
        def source
          @source ||= config_params(:source) || self.class.const_get(:DEFAULT_SOURCE)
        end

        #: () -> String
        def tag
          @tag ||= self.class.name.split("::").last.underscore
        end

        # parse Record object
        # @param _record [Record]
        # @return [Record, nil]
        #: (Fusuma::Plugin::Events::Records::Record) -> Fusuma::Plugin::Events::Records::Record?
        def parse_record(_record)
          nil
        end
      end
    end
  end
end
