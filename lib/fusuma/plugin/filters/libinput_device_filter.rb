require_relative '../../device.rb'

module Fusuma
  module Plugin
    module Filters
      # Filter device log
      class LibinputDeviceFilter < Filter
        DEFAULT_SOURCE = 'libinput_command_input'.freeze

        def filter_record?(record)
          device_ids.none? { |device_id| record =~ /^\s?#{device_id}/ }
        end

        # TODO: read device names from config.yml
        def device_names
          @options.fetch(:device, [])
        end

        private

        def device_ids
          @device_ids ||= Device.ids
        end

        # TODO: read option[:filter][:libinput_device] from conig instead of
        # `Device.given_device=`
      end
    end
  end
end
