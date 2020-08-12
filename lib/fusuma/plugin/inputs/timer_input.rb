# frozen_string_literal: true

require_relative './input.rb'

module Fusuma
  module Plugin
    module Inputs
      # libinput commands wrapper
      class TimerInput < Input
        DEFAULT_INTERVAL = 0.3
        def config_param_types
          {
            'interval': [Float]
          }
        end

        attr_reader :writer

        def io
          @io ||= begin
                    reader, writer = create_io
                    @pid = start(reader, writer)

                    reader
                  end
        end

        def start(reader, writer)
          pid = fork do
            timer_loop(reader, writer)
          end
          Process.detach(pid)
          writer.close
          pid
        end

        def timer_loop(reader, writer)
          reader.close
          begin
            loop do
              sleep interval
              writer.puts 'timer'
            end
          rescue Errno::EPIPE
            exit 0
          rescue StandardError => e
            MultiLogger.error e
          end
        end

        private

        def create_io
          IO.pipe
        end

        def interval
          config_params(:interval) || DEFAULT_INTERVAL
        end
      end
    end
  end
end
