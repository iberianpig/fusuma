# frozen_string_literal: true

require_relative "../base"
require_relative "../events/event"

module Fusuma
  module Plugin
    module Inputs
      # Inherite this base
      # @abstract Subclass and override {#io} to implement
      class Input < Base
        #: (*nil) -> void
        def initialize(*args)
          super
          @tag = self.class.name.split("Inputs::").last.underscore
        end

        attr_reader :tag

        # Wait multiple inputs until it becomes readable
        # @param inputs [Array<Input>]
        # @return [Event]
        #: (Array[untyped]) -> Fusuma::Plugin::Events::Event
        def self.select(inputs)
          ios = IO.select(inputs.map(&:io))
          io = ios&.first&.first

          input = inputs.find { |i| i.io == io }

          input.create_event(record: input.read_from_io)
        end

        # @return [String, Record]
        # IO#readline is blocking method
        # so input plugin must write line to pipe (include `\n`)
        # or, override read_from_io and implement your own read method
        #: () -> String
        def read_from_io
          io.readline(chomp: true)
        rescue EOFError => e
          MultiLogger.error "#{self.class.name}: #{e}"
          MultiLogger.error "Shutdown fusuma process..."
          Process.kill("TERM", Process.pid)
        rescue => e
          MultiLogger.error "#{self.class.name}: #{e}"
          exit 1
        end

        # @return [IO]
        #: () -> nil
        def io
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # @return [Event]
        #: (?record: String) -> Fusuma::Plugin::Events::Event
        def create_event(record: "dummy input")
          e = Events::Event.new(tag: tag, record: record)
          MultiLogger.debug(input_event: e)
          e
        end
      end
    end
  end
end
