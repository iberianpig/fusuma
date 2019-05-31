# frozen_string_literal: true

require_relative '../base.rb'
require_relative '../formats/event_format.rb'

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

        def run
          yield(event)
        end

        def event(record: 'DummyInput')
          Formats::Event.new(tag: tag, record: record).tap do |e|
            MultiLogger.debug(innput_event: e)
          end
        end

        def tag
          self.class.name.split('Inputs::').last.underscore
        end
      end

      # Generate input
      class Generator
        # @example Generate input plugins
        #  options = {:inputs=>{:libinput_command_input=>{"enable-tap"=>true}}}
        #  Generator.new(options: options).generate
        #  => [#<Fusuma::Plugin::Inputs::LibinputCommandInput:0x0056011e552a60 @options=[]>]
        # @param options [Hash]
        def initialize(options:)
          @options = options.fetch(:inputs, {})
        end

        # Generate input plugins
        # @return [Array<Input>]
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
