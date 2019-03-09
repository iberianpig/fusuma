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

        def initialize(options = {})
          @options = options
        end

        # @param event [String]
        # @return [Event]
        def parse(event)
          event.tap do |e|
            new_record = parse_record(e.record)
            if new_record
              e.record = new_record
              e.tag = tag
            end
          end
        end

        protected

        def tag
          self.class.name.split('::').last.underscore
        end

        def parse_record(record)
          # "DummyParsed#{record}"
        end
      end

      # Generate parser
      class Generator
        # DUMMY_OPTIONS = { parser: { dummy: 'dummy' } }.freeze
        # @param options [Hash]
        def initialize(options:)
          @options = options.fetch(:parsers, {})
        end

        # and generate parser
        # @return [parser]
        def generate
          plugins.map do |klass|
            klass.generate(options: @options)
          end.compact
        end

        # parser plugins
        # @return [Array]
        def plugins
          Parser.plugins
        end
      end
    end
  end
end
