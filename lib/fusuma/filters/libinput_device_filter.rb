require_relative '../device.rb'

module Fusuma
  module Filters
    # Filter device log
    class LibinputDeviceFilter < BaseFilter
      def initialize(*device_names)
        @device_names = device_names
      end

      # @param line [String]
      # @return [String]
      def filter(line)
        return '' if device_ids.none? do |device_id|
          line =~ /^\s?#{device_id}/
        end

        line
      end

      def device_ids
        Device.ids
      end

      # TODO: read option[:filter][:libinput_device] from conig instead of
      # `Device.given_device=`

      class << self
        # OPTIONS = { filter: { libinput_device: 'DLL075B:01 06CB:76AF Touchpad' } }.freeze
        def generate(options:)
          device_names = options[:filter][:libinput_device]
          new(device_names)
        end
      end
    end
  end
end
