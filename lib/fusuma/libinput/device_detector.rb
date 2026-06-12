# frozen_string_literal: true

require "fiddle"
require_relative "../device"

module Fusuma
  module Libinput
    # Detect input devices via libinput FFI (replaces CLI-based device detection)
    class DeviceDetector
      # @return [Array<Device>] detected devices with gesture capability
      #: () -> Array[Fusuma::Device]
      def detect
        interface = Interface.new
        context = Context.new(interface)

        devices = []

        # Add all /dev/input/event* devices
        event_device_paths.each do |path|
          context.add_device(path)
        rescue => e
          # Skip devices we can't open
          MultiLogger.debug("Skipping device #{path}: #{e.message}")
        end

        # Process DEVICE_ADDED events
        context.each_event do |event_ptr|
          event_type = Functions::EVENT_GET_TYPE.call(event_ptr)
          next unless event_type == Constants::DEVICE_ADDED

          device_ptr = Functions::EVENT_GET_DEVICE.call(event_ptr)

          name_ptr = Functions::DEVICE_GET_NAME.call(device_ptr)
          name = name_ptr.to_s

          sysname_ptr = Functions::DEVICE_GET_SYSNAME.call(device_ptr)
          sysname = sysname_ptr.to_s

          capabilities = Constants::CAPABILITY_MAP.each_with_object([]) do |(cap, cap_name), caps|
            caps << cap_name if Functions::DEVICE_HAS_CAPABILITY.call(device_ptr, cap) != 0
          end

          device = Fusuma::Device.new(
            id: sysname,
            name: name,
            capabilities: capabilities.join(" "),
            available: capabilities.include?("gesture")
          )
          devices << device
        end

        devices
      ensure
        context&.destroy
      end

      private

      # @return [Array<String>] paths matching /dev/input/event*
      def event_device_paths
        Dir.glob("/dev/input/event*").sort
      end
    end
  end
end
