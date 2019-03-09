require_relative '../base.rb'

module Fusuma
  module Plugin
    # input class
    module Inputs
      # Inherite this base
      class Input < Base
        attr_reader :options

        def initialize(options = {})
          @options = options
        end

        Event = Struct.new(:time, :tag, :record)

        def run
          yield(event)
        end

        def event(record: 'DummyInput')
          Event.new(Time.now, tag, record)
        end

        def tag
          self.class.name.split('Inputs::').last.underscore
        end
      end

      # Generate input
      class Generator
        # DUMMY_OPTIONS = { input: { libinput_command: '--enable-tap' } }.freeze
        # @param options [Hash]
        def initialize(options:)
          @options = options.fetch(:inputs, {})
        end

        # and generate input
        # @return [input]
        def generate
          plugins.map do |klass|
            klass.generate(options: @options)
          end.compact
        end

        # input plugins
        # @return [Array]
        def plugins
          Input.plugins
        end
      end
    end
  end
end
