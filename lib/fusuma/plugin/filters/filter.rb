# frozen_string_literal: true

require_relative '../base.rb'

module Fusuma
  module Plugin
    # filter class
    module Filters
      # Inherite this base
      class Filter < Base
        # Filter input event
        # @param event [Event]
        # @return [Event, nil]
        def filter(event)
          event.tap do |e|
            next if e.tag != source
            next if keep?(e.record)

            MultiLogger.debug(filtered: e)

            break nil
          end
        end

        # @abstract override `#keep?` to implement
        # @param record [String]
        # @return [True, False]
        def keep?(record)
          true if record
        end

        # Set source for tag from config.yml.
        # DEFAULT_SOURCE is defined in each Filter plugins.
        def source
          @source ||= config_params.fetch(:source,
                                          self.class.const_get('DEFAULT_SOURCE'))
        end
      end
    end
  end
end
