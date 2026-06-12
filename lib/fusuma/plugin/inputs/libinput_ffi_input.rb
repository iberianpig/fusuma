# frozen_string_literal: true

require_relative "input"
require_relative "../events/records/gesture_record"
require_relative "../events/records/touch_record"
require_relative "../events/records/pointer_record"

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
      #         device: "Magic Touchpad"   # optional, like the CLI --device
      #         touch-events: true         # TouchRecord from touchscreens (default: true)
      #         pointer-events: false      # PointerRecord motion/button/scroll (default: false)
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
            device: [String, Array],
            "enable-tap": [TrueClass, FalseClass],
            "enable-dwt": [TrueClass, FalseClass],
            "disable-dwt": [TrueClass, FalseClass],
            "touch-events": [TrueClass, FalseClass],
            "pointer-events": [TrueClass, FalseClass]
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

        # Read a Record (gesture/touch/pointer) from the pipe
        # @return [Events::Records::Record]
        #: () -> Fusuma::Plugin::Events::Records::Record
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
        ensure
          # Let the reader see EOF; read_from_io then shuts fusuma down
          # (same behavior as the CLI input when its subprocess dies)
          begin
            writer.close
          rescue IOError
            # already closed
          end
        end

        #: (Fiddle::Pointer, IO) -> void
        def process_event(event_ptr, writer)
          event_type = Libinput::Functions::EVENT_GET_TYPE.call(event_ptr)

          if event_type == Libinput::Constants::DEVICE_ADDED
            apply_device_config(event_ptr)
            return
          end

          record = extract_record(event_ptr, event_type)
          return unless record

          write_record(writer, record)
        end

        # @return [Events::Records::Record, nil]
        #: (Fiddle::Pointer, Integer) -> Fusuma::Plugin::Events::Records::Record?
        def extract_record(event_ptr, event_type)
          if Libinput::Constants::GESTURE_EVENT_TYPE_RANGE.cover?(event_type)
            Libinput::GestureEvent.new(event_ptr: event_ptr, event_type: event_type)
              .to_gesture_record
          elsif touch_events? && Libinput::Constants::TOUCH_STATUS_MAP.key?(event_type)
            Libinput::TouchEvent.new(event_ptr: event_ptr, event_type: event_type)
              .to_touch_record
          elsif pointer_events? && Libinput::Constants::POINTER_STATUS_MAP.key?(event_type)
            Libinput::PointerEvent.new(event_ptr: event_ptr, event_type: event_type)
              .to_pointer_record
          end
        end

        #: (IO, Fusuma::Plugin::Events::Records::Record) -> void
        def write_record(writer, record)
          data = Marshal.dump(record)
          writer.write([data.bytesize].pack("N") + data)
          writer.flush
        end

        # Touch events are emitted by default (only touchscreens produce
        # them); cache the lookup since this runs per event
        #: () -> bool
        def touch_events?
          @touch_events = config_params(:"touch-events") != false if @touch_events.nil?
          @touch_events
        end

        # Pointer events (motion/button/scroll) are high-frequency, so
        # they are opt-in
        #: () -> bool
        def pointer_events?
          @pointer_events = config_params(:"pointer-events") == true if @pointer_events.nil?
          @pointer_events
        end

        # Equivalent of the CLI input's --enable-tap / --enable-dwt /
        # --disable-dwt options, applied per device as it appears
        #: (Fiddle::Pointer) -> void
        def apply_device_config(event_ptr)
          device_ptr = Libinput::Functions::EVENT_GET_DEVICE.call(event_ptr)

          disable_unmatched_device(device_ptr)

          if config_params(:"enable-tap")
            Libinput::Functions::TAP_SET_ENABLED.call(device_ptr, 1)
          end

          if config_params(:"enable-dwt")
            Libinput::Functions::DWT_SET_ENABLED.call(device_ptr, 1)
          elsif config_params(:"disable-dwt")
            Libinput::Functions::DWT_SET_ENABLED.call(device_ptr, 0)
          end
        end

        # Equivalent of the CLI input's --device option: when `device:` is
        # configured, gesture devices whose name does not match are muted
        # via send_events mode. Non-gesture devices (e.g. keyboards) stay
        # enabled so libinput's disable-while-typing keeps working.
        #: (Fiddle::Pointer) -> void
        def disable_unmatched_device(device_ptr)
          patterns = Array(config_params(:device))
          return if patterns.empty?

          gesture = Libinput::Constants::DEVICE_CAP_GESTURE
          return if Libinput::Functions::DEVICE_HAS_CAPABILITY.call(device_ptr, gesture).zero?

          name = Libinput::Functions::DEVICE_GET_NAME.call(device_ptr).to_s
          # regex match, same semantics as libinput_device_filter's keep_device
          return if patterns.any? { |pattern| name.match?(pattern) }

          Libinput::Functions::SEND_EVENTS_SET_MODE.call(
            device_ptr, Libinput::Constants::SEND_EVENTS_DISABLED
          )
          MultiLogger.debug("FFI: disabled events from unmatched device: #{name}")
        end
      end
    end
  end
end
