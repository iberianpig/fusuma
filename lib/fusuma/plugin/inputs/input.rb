# frozen_string_literal: true

require_relative "../base"
require_relative "../events/event"

module Fusuma
  module Plugin
    module Inputs
      # Inherite this base
      # @abstract Subclass and override {#io} to implement
      class Input < Base
        def initialize(*args)
          super(*args)
          @tag = self.class.name.split("Inputs::").last.underscore
        end

        attr_reader :tag

        # Wait multiple inputs until it becomes readable
        # @param inputs [Array<Input>]
        # @return [Event]
        def self.select(inputs)
          ios = IO.select(inputs.map(&:io))
          io = ios&.first&.first

          input = inputs.find { |i| i.io == io }

          begin
            # NOTE: io.readline is blocking method
            # each input plugin must write line to pipe (include `\n`)
            line = io.readline(chomp: true)
          rescue EOFError => e
            MultiLogger.error "#{input.class.name}: #{e}"
            MultiLogger.error "Shutdown fusuma process..."
            Process.kill("TERM", Process.pid)
          rescue => e
            MultiLogger.error "#{input.class.name}: #{e}"
            exit 1
          end
          input.create_event(record: line)
        end

        # @return [Integer]
        def pid
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # @return [IO]
        def io
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # @return [Event]
        def create_event(record: "dummy input")
          e = Events::Event.new(tag: tag, record: record)
          MultiLogger.debug(input_event: e)
          e
        end
      end
    end
  end
end
