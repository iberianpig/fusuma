require_relative '../../device.rb'

module Fusuma
  module Plugin
    module Filters
      # Filter device log
      class LibinputDeviceFilter < Filter
        DEFAULT_SOURCE = 'libinput_command_input'.freeze

        def initialize(options)
          @source = options.fetch(:source, DEFAULT_SOURCE)
          @device_names = options.fetch(:device, [])
        end

        # @param line [Event]
        # @return [Event, nil]
        def filter(event)
          return event unless event.tag == @source
          return nil if device_ids.none? do |device_id|
            event.record =~ /^\s?#{device_id}/
          end

          event
        end

        def device_ids
          Device.ids
        end

        # TODO: read option[:filter][:libinput_device] from conig instead of
        # `Device.given_device=`
      end
    end
  end
end
