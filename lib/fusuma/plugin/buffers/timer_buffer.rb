# frozen_string_literal: true

require_relative './buffer.rb'

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class TimerBuffer < Buffer
        DEFAULT_SOURCE = 'timer_input'
        DEFAULT_SECONDS_TO_KEEP = 60

        def config_param_types
          {
            'source': [String],
            'seconds_to_keep': [Float, Integer]
          }
        end

        # @param event [Event]
        # @return [Buffer, NilClass]
        def buffer(event)
          return if event&.tag != source

          @events.push(event)
          self
        end

        def clear_expired(current_time: Time.now)
          @seconds_to_keep ||= (config_params(:seconds_to_keep) || DEFAULT_SECONDS_TO_KEEP)
          @events.each do |e|
            break if current_time - e.time < @seconds_to_keep

            MultiLogger.debug("#{self.class.name}##{__method__}")

            @events.delete(e)
          end
        end

        def empty?
          @events.empty?
        end
      end
    end
  end
end
