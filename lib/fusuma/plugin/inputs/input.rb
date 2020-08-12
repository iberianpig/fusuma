# frozen_string_literal: true

require_relative '../base.rb'
require_relative '../events/event.rb'

module Fusuma
  module Plugin
    module Inputs
      # Inherite this base
      # @abstract Subclass and override {#io} to implement
      class Input < Base
        # Wait multiple inputs until it becomes readable
        # and read lines with nonblock
        # @param inputs [Array<Input>]
        # @return Event
        def self.select(inputs)
          ios = IO.select(inputs.map(&:io))
          io = ios&.first&.first

          input = inputs.find { |i| i.io == io }

          begin
            line = io.readline_nonblock("\n").chomp
          rescue StandardError => e
            warn e
            exit 1
          end

          input.create_event(record: line)
        end

        def io
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        def create_event(record: 'dummy input')
          Events::Event.new(tag: tag, record: record).tap do |e|
            MultiLogger.debug(input_event: e)
          end
        end

        def tag
          self.class.name.split('Inputs::').last.underscore
        end
      end
    end
  end
end

# ref: https://github.com/Homebrew/brew/blob/6b2dbbc96f7d8aa12f9b8c9c60107c9cc58befc4/Library/Homebrew/extend/io.rb
class IO
  def readline_nonblock(sep = $INPUT_RECORD_SEPARATOR)
    line = +''
    buffer = +''

    loop do
      break if buffer == sep

      read_nonblock(1, buffer)
      line.concat(buffer)
    end

    line.freeze
  rescue IO::WaitReadable, EOFError => e
    raise e if line.empty?

    line.freeze
  end
end
