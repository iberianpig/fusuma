# frozen_string_literal: true

require "fiddle"

module Fusuma
  module Libinput
    # Wrapper around libinput context (path-based or udev-based)
    class Context
      attr_reader :ptr

      # Create a path-based context
      # @param interface [Interface]
      #: (Fusuma::Libinput::Interface) -> void
      def initialize(interface)
        @interface = interface
        @ptr = Functions::PATH_CREATE_CONTEXT.call(interface.to_ptr, Fiddle::NULL)
        raise "Failed to create libinput context" if @ptr.null?

        # GC guard: prevent Fiddle::Pointer device references from being collected
        @devices = []
      end

      # Create a udev-based context
      # @param interface [Interface]
      # @param seat [String]
      # @return [Context]
      #: (Fusuma::Libinput::Interface, ?seat: String) -> Fusuma::Libinput::Context
      def self.create_udev(interface, seat: "seat0")
        ctx = allocate
        ctx.instance_variable_set(:@interface, interface)
        ctx.instance_variable_set(:@devices, [])

        udev = Functions::UDEV_NEW.call
        raise "Failed to create udev context" if udev.null?

        ptr = Functions::UDEV_CREATE_CONTEXT.call(interface.to_ptr, Fiddle::NULL, udev)
        Functions::UDEV_UNREF.call(udev)
        raise "Failed to create libinput udev context" if ptr.null?

        ret = Functions::UDEV_ASSIGN_SEAT.call(ptr, seat)
        raise "Failed to assign seat '#{seat}'" if ret != 0

        ctx.instance_variable_set(:@ptr, ptr)
        ctx
      end

      # @param path [String] device path (e.g. "/dev/input/event4")
      # @return [Fiddle::Pointer] device pointer
      #: (String) -> Fiddle::Pointer?
      def add_device(path)
        dev = Functions::PATH_ADD_DEVICE.call(@ptr, path)
        raise "Failed to add device: #{path}" if dev.null?

        @devices << dev
        dev
      end

      # @return [Integer] file descriptor for polling
      #: () -> Integer
      def fd
        Functions::GET_FD.call(@ptr)
      end

      # @return [IO] Ruby IO wrapping the fd (non-owning)
      #: () -> IO
      def io
        @io ||= IO.for_fd(fd, autoclose: false)
      end

      # Dispatch pending events
      # @return [Integer] 0 on success, negative errno on failure
      #: () -> Integer
      def dispatch
        Functions::DISPATCH.call(@ptr)
      end

      # Get next event from the queue
      # @return [Fiddle::Pointer, nil] event pointer or nil when no more events
      #: () -> Fiddle::Pointer?
      def get_event
        event = Functions::GET_EVENT.call(@ptr)
        return nil if event.null?

        event
      end

      # Iterate over all pending events
      # @yield [event_ptr] each event pointer
      #: () { (Fiddle::Pointer) -> void } -> void
      def each_event
        dispatch
        while (event = get_event)
          yield event
          Functions::EVENT_DESTROY.call(event)
        end
      end

      # Clean up the context
      #: () -> void
      def destroy
        return unless @ptr && !@ptr.null?

        Functions::UNREF.call(@ptr)
        @ptr = nil
        @io = nil
      end
    end
  end
end
