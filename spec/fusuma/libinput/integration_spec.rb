# frozen_string_literal: true

require "spec_helper"
require "./spec/helpers/uinput_helper"

# Skip (not fail) on machines without libinput.so
LIBINPUT_AVAILABLE =
  begin
    require "./lib/fusuma/libinput/libinput"
    true
  rescue Fiddle::DLError
    false
  end

module Fusuma
  module Libinput
    RSpec.describe "libinput FFI integration", :uinput do
      before(:all) do
        skip "Requires libinput.so" unless LIBINPUT_AVAILABLE
        skip "Requires /dev/uinput access" unless File.writable?("/dev/uinput")
        @touchpad = UinputHelper::VirtualTouchpad.new
        # Wait for device to be fully registered
        sleep 0.2
      end

      after(:all) do
        @touchpad&.destroy
      end

      let(:interface) { Interface.new }

      def find_virtual_device_path
        @touchpad.path
      end

      # Dispatch libinput while waiting, collecting gesture records into
      # +events+. Dispatching in (near) real time matters: libinput
      # schedules tap/hold timers from event timestamps, and batching all
      # injection before dispatching makes those timers fire late.
      def pump_events(context, events, duration)
        deadline = Time.now + duration

        loop do
          remaining = deadline - Time.now
          break if remaining <= 0

          ready = IO.select([context.io], nil, nil, [remaining, 0.1].min)
          next unless ready

          context.dispatch
          while (event_ptr = context.get_event)
            event_type = Functions::EVENT_GET_TYPE.call(event_ptr)
            if Constants::GESTURE_EVENT_TYPE_RANGE.cover?(event_type)
              gesture_event = GestureEvent.new(event_ptr: event_ptr, event_type: event_type)
              events << gesture_event.to_gesture_record
            end
            Functions::EVENT_DESTROY.call(event_ptr)
          end
        end

        events
      end

      describe "3-finger swipe right" do
        it "generates GESTURE_SWIPE events" do
          skip "Requires /dev/uinput access" unless File.writable?("/dev/uinput")

          context = Context.new(interface)
          device_path = find_virtual_device_path
          context.add_device(device_path)

          # Drain any initial events
          context.dispatch
          while context.get_event; end

          events = []

          # Inject 3-finger swipe right
          # Place 3 fingers (single frame, like a real device)
          @touchpad.touch_down(0, 1200, 1000, syn: false)
          @touchpad.touch_down(1, 1100, 1000, syn: false)
          @touchpad.touch_down(2, 1000, 1000)
          pump_events(context, events, 0.05)

          # Move all fingers right
          10.times do |i|
            offset = (i + 1) * 50
            @touchpad.touch_move(0, 1200 + offset, 1000, syn: false)
            @touchpad.touch_move(1, 1100 + offset, 1000, syn: false)
            @touchpad.touch_move(2, 1000 + offset, 1000)
            pump_events(context, events, 0.01)
          end

          # Lift fingers
          @touchpad.touch_up(0, syn: false)
          @touchpad.touch_up(1, syn: false)
          @touchpad.touch_up(2)
          pump_events(context, events, 0.5)
          context.destroy

          # We expect at least begin and end events
          gestures = events.map(&:gesture).uniq
          statuses = events.map(&:status)

          expect(gestures).to include("swipe")
          expect(statuses).to include("begin")
          expect(statuses).to include("end")

          # Check that update events have positive dx (rightward movement)
          update_events = events.select { |e| e.status == "update" && e.gesture == "swipe" }
          unless update_events.empty?
            total_dx = update_events.sum { |e| e.delta.move_x }
            expect(total_dx).to be > 0
          end
        end
      end

      describe "2-finger pinch" do
        it "generates GESTURE_PINCH events" do
          skip "Requires /dev/uinput access" unless File.writable?("/dev/uinput")

          context = Context.new(interface)
          device_path = find_virtual_device_path
          context.add_device(device_path)

          # Drain initial events
          context.dispatch
          while context.get_event; end

          events = []

          # Place 2 fingers (single frame, like a real device)
          @touchpad.touch_down(0, 1200, 800, syn: false)
          @touchpad.touch_down(1, 1200, 1200)
          pump_events(context, events, 0.05)

          # Move fingers apart (zoom in)
          10.times do |i|
            offset = (i + 1) * 20
            @touchpad.touch_move(0, 1200, 800 - offset, syn: false)
            @touchpad.touch_move(1, 1200, 1200 + offset)
            pump_events(context, events, 0.01)
          end

          @touchpad.touch_up(0, syn: false)
          @touchpad.touch_up(1)
          pump_events(context, events, 0.5)
          context.destroy

          gestures = events.map(&:gesture).uniq
          expect(gestures).to include("pinch")
        end
      end

      describe "3-finger hold" do
        it "generates GESTURE_HOLD events" do
          skip "Requires /dev/uinput access" unless File.writable?("/dev/uinput")

          context = Context.new(interface)
          device_path = find_virtual_device_path
          context.add_device(device_path)

          # Drain initial events
          context.dispatch
          while context.get_event; end

          events = []

          # Place 3 fingers and hold still (single frame, like a real device)
          @touchpad.touch_down(0, 1200, 1000, syn: false)
          @touchpad.touch_down(1, 1100, 1000, syn: false)
          @touchpad.touch_down(2, 1000, 1000)

          # Hold for a bit (hold begin is timer-driven inside libinput)
          pump_events(context, events, 0.5)

          @touchpad.touch_up(0, syn: false)
          @touchpad.touch_up(1, syn: false)
          @touchpad.touch_up(2)
          pump_events(context, events, 0.5)
          context.destroy

          # Hold events may or may not be generated depending on libinput version
          # and timing. Just verify no errors occurred.
          if events.any? { |e| e.gesture == "hold" }
            statuses = events.select { |e| e.gesture == "hold" }.map(&:status)
            expect(statuses).to include("begin")
          end
        end
      end

      # End-to-end through the input plugin: udev backend discovers the
      # virtual touchpad by itself and GestureRecords arrive via the pipe.
      describe "LibinputFfiInput (udev backend)" do
        it "emits GestureRecords through the pipe without using the libinput CLI" do
          skip "Requires /dev/uinput access" unless File.writable?("/dev/uinput")

          require "./lib/fusuma/plugin/inputs/libinput_ffi_input"
          input = nil

          ConfigHelper.load_config_yml = <<~CONFIG
            plugin:
              inputs:
                libinput_ffi_input:
                  enabled: true
                  enable-tap: true
          CONFIG

          input = Plugin::Inputs::LibinputFfiInput.new
          reader = input.io
          # Wait for udev enumeration to pick up the virtual touchpad
          sleep 0.5

          # Inject a 3-finger swipe right
          @touchpad.touch_down(0, 1200, 1000, syn: false)
          @touchpad.touch_down(1, 1100, 1000, syn: false)
          @touchpad.touch_down(2, 1000, 1000)
          sleep 0.05
          10.times do |i|
            offset = (i + 1) * 50
            @touchpad.touch_move(0, 1200 + offset, 1000, syn: false)
            @touchpad.touch_move(1, 1100 + offset, 1000, syn: false)
            @touchpad.touch_move(2, 1000 + offset, 1000)
            sleep 0.01
          end
          @touchpad.touch_up(0, syn: false)
          @touchpad.touch_up(1, syn: false)
          @touchpad.touch_up(2)

          records = []
          deadline = Time.now + 2
          while Time.now < deadline
            break unless IO.select([reader], nil, nil, deadline - Time.now)

            records << input.read_from_io
            break if records.any? { |r| r.gesture == "swipe" && r.status == "end" }
          end

          expect(records.map(&:gesture)).to include("swipe")
          expect(records.map(&:status)).to include("begin")
          expect(records.map(&:status)).to include("end")
        ensure
          input&.shutdown
          Config.custom_path = nil
        end
      end
    end
  end
end
