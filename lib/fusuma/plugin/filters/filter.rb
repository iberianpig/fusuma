# frozen_string_literal: true

require_relative "../base"

module Fusuma
  module Plugin
    module Filters
      # Filter to keep/discard events from input plugin
      class Filter < Base
        # Filter input event
        # @param event [Event]
        # @return [Event] when keeping event
        # @return [NilClass] when discarding record
        #: (Fusuma::Plugin::Events::Event) -> Fusuma::Plugin::Events::Event?
        def filter(event)
          return event if !/#{source}/.match?(event.tag)

          return event if keep?(event.record)

          nil
        end

        # @abstract override `#keep?` to implement
        # @param record [String]
        # @return [True]  when keeping record
        # @return [False] when discarding record
        def keep?(record)
          true if record
        end

        # Set source for tag from config.yml.
        # DEFAULT_SOURCE is defined in each Filter plugins.
        #: () -> String
        def source
          @source ||= config_params(:source) || self.class.const_get(:DEFAULT_SOURCE)
        end
      end
    end
  end
end
