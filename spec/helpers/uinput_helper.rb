# frozen_string_literal: true

require "fiddle"
require "fiddle/import"

module Fusuma
  # Helper for creating virtual input devices via /dev/uinput
  # Requires root or uinput group access
  module UinputHelper
    # Linux input event constants
    EV_SYN = 0x00
    EV_KEY = 0x01
    EV_ABS = 0x03

    SYN_REPORT = 0x00

    BTN_TOUCH = 0x14a
    BTN_TOOL_FINGER = 0x145
    BTN_TOOL_DOUBLETAP = 0x14d
    BTN_TOOL_TRIPLETAP = 0x14e
    BTN_TOOL_QUADTAP = 0x14f

    ABS_X = 0x00
    ABS_Y = 0x01
    ABS_MT_SLOT = 0x2f
    ABS_MT_TRACKING_ID = 0x39
    ABS_MT_POSITION_X = 0x35
    ABS_MT_POSITION_Y = 0x36

    INPUT_PROP_POINTER = 0x00
    INPUT_PROP_DIRECT = 0x01

    # ioctl request codes
    UI_SET_EVBIT = 0x40045564
    UI_SET_KEYBIT = 0x40045565
    UI_SET_ABSBIT = 0x40045567
    UI_SET_PROPBIT = 0x4004556e
    UI_DEV_SETUP = 0x405c5503
    UI_DEV_CREATE = 0x5501
    UI_DEV_DESTROY = 0x5502

    # struct input_event (time_sec, time_usec, type, code, value)
    # On 64-bit: 8+8+2+2+4 = 24 bytes
    INPUT_EVENT_FORMAT = "qqSSl"
    INPUT_EVENT_SIZE = 24

    # uinput_setup struct
    # struct input_id (bustype, vendor, product, version) = 8 bytes
    # name[80] = 80 bytes
    # ff_effects_max = 4 bytes
    # Total = 92 bytes
    UINPUT_SETUP_FORMAT = "SSSS a80 L"

    # uinput_abs_setup struct
    # code (u16) + padding + struct input_absinfo (value, min, max, fuzz, flat, resolution) = 6*4=24
    UINPUT_ABS_SETUP_FORMAT = "S x2 llllll"
    # _IOW('U', 4, struct uinput_abs_setup) -- struct is 28 bytes (0x1c)
    UI_ABS_SETUP = 0x401c5504

    MAX_SLOTS = 10
    ABS_MAX_X = 3000
    ABS_MAX_Y = 2000

    DEVICE_NAME = "fusuma-test-touchpad"

    class VirtualTouchpad
      attr_reader :fd, :path

      def initialize
        @fd = IO.sysopen("/dev/uinput", File::WRONLY | File::NONBLOCK)
        @io = IO.for_fd(@fd, "wb", autoclose: false)
        @active_slots = {}
        @key_state = Hash.new(0)
        setup_device
        @path = resolve_device_path
      end

      # NOTE: Real touchpads report all slot updates in a single frame
      # (one SYN_REPORT). Pass syn: false for all but the last finger of a
      # multi-finger update; per-finger frames arrive microseconds apart and
      # trigger libinput's touch-jump detection, which discards the motion.
      def touch_down(slot, x, y, tracking_id = nil, syn: true)
        tracking_id ||= slot + 1
        write_event(EV_ABS, ABS_MT_SLOT, slot)
        write_event(EV_ABS, ABS_MT_TRACKING_ID, tracking_id)
        write_event(EV_ABS, ABS_MT_POSITION_X, x)
        write_event(EV_ABS, ABS_MT_POSITION_Y, y)

        @active_slots[slot] = true
        update_tool_buttons
        syn_report if syn
      end

      def touch_move(slot, x, y, syn: true)
        write_event(EV_ABS, ABS_MT_SLOT, slot)
        write_event(EV_ABS, ABS_MT_POSITION_X, x)
        write_event(EV_ABS, ABS_MT_POSITION_Y, y)
        syn_report if syn
      end

      def touch_up(slot, syn: true)
        write_event(EV_ABS, ABS_MT_SLOT, slot)
        write_event(EV_ABS, ABS_MT_TRACKING_ID, -1)

        @active_slots.delete(slot)
        update_tool_buttons
        syn_report if syn
      end

      def syn_report
        write_event(EV_SYN, SYN_REPORT, 0)
      end

      def destroy
        ioctl_simple(UI_DEV_DESTROY)
        @io.close
      end

      private

      def setup_device
        # Set event bits
        ioctl_int(UI_SET_EVBIT, EV_SYN)
        ioctl_int(UI_SET_EVBIT, EV_KEY)
        ioctl_int(UI_SET_EVBIT, EV_ABS)

        # Set key bits
        ioctl_int(UI_SET_KEYBIT, BTN_TOUCH)
        ioctl_int(UI_SET_KEYBIT, BTN_TOOL_FINGER)
        ioctl_int(UI_SET_KEYBIT, BTN_TOOL_DOUBLETAP)
        ioctl_int(UI_SET_KEYBIT, BTN_TOOL_TRIPLETAP)
        ioctl_int(UI_SET_KEYBIT, BTN_TOOL_QUADTAP)

        # Set abs bits
        [ABS_X, ABS_Y, ABS_MT_SLOT, ABS_MT_TRACKING_ID,
          ABS_MT_POSITION_X, ABS_MT_POSITION_Y].each do |abs|
          ioctl_int(UI_SET_ABSBIT, abs)
        end

        # Set property
        ioctl_int(UI_SET_PROPBIT, INPUT_PROP_POINTER)

        # Setup abs info
        setup_abs(ABS_X, 0, ABS_MAX_X, 0, 0, 10)
        setup_abs(ABS_Y, 0, ABS_MAX_Y, 0, 0, 10)
        setup_abs(ABS_MT_SLOT, 0, MAX_SLOTS - 1, 0, 0, 0)
        setup_abs(ABS_MT_TRACKING_ID, 0, 65535, 0, 0, 0)
        setup_abs(ABS_MT_POSITION_X, 0, ABS_MAX_X, 0, 0, 10)
        setup_abs(ABS_MT_POSITION_Y, 0, ABS_MAX_Y, 0, 0, 10)

        # Device setup
        setup_data = [
          0x03,  # BUS_USB
          0x1234, # vendor
          0x5678, # product
          0x0001, # version
          DEVICE_NAME, # name
          0      # ff_effects_max
        ].pack(UINPUT_SETUP_FORMAT)
        ioctl_buf(UI_DEV_SETUP, setup_data)

        # Create device
        ioctl_simple(UI_DEV_CREATE)
      end

      # Find this device's event node via sysfs by name.
      # Event numbers are reused by the kernel, so guessing from
      # /dev/input/event* ordering is unreliable.
      def resolve_device_path
        deadline = Time.now + 2
        while Time.now < deadline
          Dir.glob("/sys/class/input/event*/device/name").each do |name_file|
            next unless File.read(name_file).strip == DEVICE_NAME

            path = "/dev/input/#{name_file[%r{event\d+}]}"
            # Wait until udev has applied permissions
            return path if File.readable?(path)
          end
          sleep 0.05
        end
        raise "Device node for #{DEVICE_NAME} did not appear"
      end

      def setup_abs(code, min, max, fuzz, flat, resolution)
        data = [code, 0, min, max, fuzz, flat, resolution].pack(UINPUT_ABS_SETUP_FORMAT)
        ioctl_buf(UI_ABS_SETUP, data)
      end

      # Report finger count via BTN_TOUCH/BTN_TOOL_* like a real touchpad.
      # libinput counts fingers on pressure-less touchpads from BTN_TOOL_*
      # (tp_fake_finger_count); without these, touches stay in HOVERING
      # state and no pointer/gesture events are generated.
      def update_tool_buttons
        count = @active_slots.size
        write_key(BTN_TOUCH, count.positive? ? 1 : 0)
        {
          1 => BTN_TOOL_FINGER,
          2 => BTN_TOOL_DOUBLETAP,
          3 => BTN_TOOL_TRIPLETAP,
          4 => BTN_TOOL_QUADTAP
        }.each do |n, code|
          write_key(code, (count == n) ? 1 : 0)
        end
      end

      def write_key(code, value)
        return if @key_state[code] == value

        @key_state[code] = value
        write_event(EV_KEY, code, value)
      end

      def write_event(type, code, value)
        now = Time.now
        data = [now.to_i, now.usec, type, code, value].pack(INPUT_EVENT_FORMAT)
        @io.syswrite(data)
      end

      def ioctl_int(request, value)
        @io.ioctl(request, value)
      end

      def ioctl_buf(request, buffer)
        @io.ioctl(request, buffer)
      end

      def ioctl_simple(request)
        @io.ioctl(request, 0)
      end
    end
  end
end
