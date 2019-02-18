require_relative './plugin_manager.rb'

module Fusuma
  module Plugin
    # parser class
    module Parsers
      # Inherite this base
      class BaseParser < Base
        # parser generate event
        # Event = Struct.new(:time, :type, :status, :body)

        def initialize(options: DummyOptions); end

        # @param line [String]
        # @retrun [Event]
        def parse(event)
          event.tap do |e|
            e.record = "DummyParsed#{e.record}"
          end
        end

        def event(record: 'DummyInput')
          Event.new(Time.now, tag, record)
        end

        def tag
          self.class.name.split('::').last.underscore
        end

        class << self
          # @return [BaseParser]
          def generate; end
        end
      end

      # Generate parser
      class Generator
        DUMMY_OPTIONS = { parser: { dummy: 'dummy' } }.freeze
        # @param options [Hash]
        def initialize(options: DUMMY_OPTIONS)
          @options = options
        end

        # and generate parser
        # @return [parser]
        def generate
          plugins.map do |klass|
            klass.generate(options: @options)
          end.compact.first
        end

        # parser plugins
        # @retrun [Array]
        def plugins
          BaseParser.plugins
        end
      end
    end
  end
end
