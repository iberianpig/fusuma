# frozen_string_literal: true

require_relative '../base.rb'

module Fusuma
  module Plugin
    # parser class
    module Parsers
      # Inherite this base
      class Parser < Base
        # parser generate event
        # Event = Struct.new(:time, :type, :status, :body)

        attr_reader :options

        def initialize(options: {})
          @options = options
        end

        # Parse Event and convert Record and Tag
        # if `#parse_record` return nil, this method will return original event
        # @param event [Event]
        # @return [Event]
        def parse(event)
          event.tap do |e|
            next if e.tag != source

            new_record = parse_record(e.record)
            next unless new_record

            e.record = new_record
            e.tag = tag
          end
        end

        # Set source for tag from config.yml.
        # DEFAULT_SOURCE is defined in each Parser plugins.
        def source
          @source ||= options.fetch(:source,
                                    self.class.const_get('DEFAULT_SOURCE'))
        end

        def tag
          self.class.name.split('::').last.underscore
        end

        # parse Record object
        # @param _record [Record]
        # @return [Record, nil]
        def parse_record(_record)
          nil
        end
      end
    end
  end
end
