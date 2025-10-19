# frozen_string_literal: true

require_relative "input"
require "timeout"

module Fusuma
  module Plugin
    module Inputs
      # libinput commands wrapper
      class TimerInput < Input
        include Singleton
        DEFAULT_INTERVAL = 5
        EPSILON_TIME = 0.02
        def config_param_types
          {
            interval: [Float]
          }
        end

        #: (*nil, ?interval: nil) -> void
        def initialize(*args, interval: nil)
          super(*args)
          @interval = interval || config_params(:interval) || DEFAULT_INTERVAL
          @early_wake_queue = Queue.new
        end

        attr_reader :interval

        #: () -> IO
        def io
          @io ||= begin
            reader, writer = create_io
            start(reader, writer)

            reader
          end
        end

        #: (IO, IO) -> Thread
        def start(reader, writer)
          Thread.new do
            timer_loop(writer)
          end
        end

        def timer_loop(writer)
          delta_t = @interval
          next_wake = Time.now + delta_t
          loop do
            sleep_time = next_wake - Time.now
            if sleep_time <= 0
              raise Timeout::Error
            end

            Timeout.timeout(sleep_time) do
              next_wake = [@early_wake_queue.deq, next_wake].min
            end
          rescue Timeout::Error
            writer.puts "timer"
            next_wake = Time.now + delta_t
          end
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e
        end

        #: (Time) -> Thread::Queue
        def wake_early(t)
          @early_wake_queue.push(t + EPSILON_TIME)
        end

        private

        def create_io
          IO.pipe
        end
      end
    end
  end
end
