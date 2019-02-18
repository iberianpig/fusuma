require_relative '../../device.rb'

module Fusuma
  module Plugin
    module Filters
      # Filter device log
      class LibinputDeviceFilter < BaseFilter
        SOURCE_TAG = 'libinput_command_input'.freeze

        def initialize(*device_names)
          @device_names = device_names
        end

        # @param line [Event]
        # @return [Event, nil]
        def filter(event)
          return event unless event.tag == SOURCE_TAG
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

        class << self
          # OPTIONS = { filter: { libinput_device: 'DLL075B:01 06CB:76AF Touchpad' } }
          def generate(options:)
            options = options[:filter][:libinput_device]
            new(options)
          end
        end
      end
    end
  end
end
