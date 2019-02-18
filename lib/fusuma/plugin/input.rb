require_relative './plugin_manager.rb'

module Fusuma
  module Plugin
    # input class
    module Inputs
      # Inherite this base
      class BaseInput < Base
        def initialize; end

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

        class << self
          # @return [BaseInput]
          def generate; end
        end
      end

      # Generate input
      class Generator
        DUMMY_OPTIONS = { input: { libinput_command: '--enable-tap' } }.freeze
        # @param options [Hash]
        def initialize(options: DUMMY_OPTIONS)
          @options = options
        end

        # and generate input
        # @return [input]
        def generate
          plugins.map do |klass|
            klass.generate(options: @options)
          end.compact.first
        end

        # input plugins
        # @retrun [Array]
        def plugins
          BaseInput.plugins
        end
      end
    end
  end
end
