# frozen_string_literal: true

require_relative "input"
require_relative "../events/records/gesture_record"

# NOTE: ../../libinput/libinput is required lazily in #start_event_loop.
# This file is auto-required at boot by Plugin::Manager, and requiring the
# FFI bindings here would dlopen("libinput.so") at require time, breaking
# fusuma entirely on systems without libinput.

module Fusuma
  module Plugin
    module Inputs
      # Input plugin using libinput FFI (Fiddle) instead of CLI subprocess.
      #
      # Disabled by default while experimental. To use it instead of the
      # CLI-based input, switch the inputs and re-point the parser source:
      #
      #   plugin:
      #     inputs:
      #       libinput_command_input:
      #         enabled: false
      #       libinput_ffi_input:
      #         enabled: true
      #         enable-tap: true
      #         disable-dwt: false
      #     parsers:
      #       libinput_gesture_parser:
      #         source: libinput_ffi_input
      class LibinputFfiInput < Input
        # Opt-in: enabled only when the config explicitly says so
        #: () -> bool
        def enabled?
          enabled_in_config == true
        end

        #: () -> Hash[Symbol, Array[Class]]
        def config_param_types
          {
            "enable-tap": [TrueClass, FalseClass],
            "enable-dwt": [TrueClass, FalseClass],
            "disable-dwt": [TrueClass, FalseClass]
          }
        end

        # @return [IO]
        #: () -> IO
        def io
          @io ||= begin
            reader, writer = create_io
            start_event_loop(writer)
            reader
          end
        end

        # Stop the event thread and release the libinput context
        #: () -> void
        def shutdown
          @event_thread&.kill
          @event_thread&.join(1)
          @context&.destroy
          @context = nil
        end

        # Read a GestureRecord from the pipe
        # @return [Events::Records::GestureRecord]
        #: () -> Fusuma::Plugin::Events::Records::GestureRecord
        def read_from_io
          # Read length-prefixed Marshal data
          len_data = io.read(4)
          unless len_data && len_data.bytesize == 4
            raise EOFError, "Unexpected end of pipe"
          end

          length = len_data.unpack1("N") #: Integer
          data = io.read(length)
          unless data && data.bytesize == length
            raise EOFError, "Incomplete data from pipe"
          end

          Marshal.load(data) # rubocop:disable Security/MarshalLoad
        rescue EOFError => e
          MultiLogger.error "#{self.class.name}: #{e}"
          MultiLogger.error "Shutdown fusuma process..."
          Process.kill("TERM", Process.pid)
        rescue => e
          MultiLogger.error "#{self.class.name}: #{e}"
          exit 1
        end

        private

        #: () -> Array[untyped]
        def create_io
          IO.pipe
        end

        #: (IO) -> void
        def start_event_loop(writer)
          require_relative "../../libinput/libinput"

          @interface = Libinput::Interface.new
          # udev backend: devices on the seat are discovered by libinput
          # itself (including hotplug); no libinput CLI is involved
          @context = Libinput::Context.create_udev(@interface)

          @event_thread = Thread.new do
            event_loop(writer)
          end
        end

        #: (IO) -> void
        def event_loop(writer)
          context_io = @context.io

          loop do
            IO.select([context_io])
            @context.each_event do |event_ptr|
              process_event(event_ptr, writer)
            end
          end
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e
        end

        #: (Fiddle::Pointer, IO) -> void
        def process_event(event_ptr, writer)
          event_type = Libinput::Functions::EVENT_GET_TYPE.call(event_ptr)

          if event_type == Libinput::Constants::DEVICE_ADDED
            apply_device_config(event_ptr)
            return
          end

          return unless Libinput::Constants::GESTURE_EVENT_TYPE_RANGE.cover?(event_type)

          gesture_event = Libinput::GestureEvent.new(
            event_ptr: event_ptr,
            event_type: event_type
          )
          record = gesture_event.to_gesture_record

          data = Marshal.dump(record)
          writer.write([data.bytesize].pack("N") + data)
          writer.flush
        end

        # Equivalent of the CLI input's --enable-tap / --enable-dwt /
        # --disable-dwt options, applied per device as it appears
        #: (Fiddle::Pointer) -> void
        def apply_device_config(event_ptr)
          device_ptr = Libinput::Functions::EVENT_GET_DEVICE.call(event_ptr)

          if config_params(:"enable-tap")
            Libinput::Functions::TAP_SET_ENABLED.call(device_ptr, 1)
          end

          if config_params(:"enable-dwt")
            Libinput::Functions::DWT_SET_ENABLED.call(device_ptr, 1)
          elsif config_params(:"disable-dwt")
            Libinput::Functions::DWT_SET_ENABLED.call(device_ptr, 0)
          end
        end
      end
    end
  end
end
