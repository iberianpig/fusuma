# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/events/records/gesture_record"

# Stub the libinput FFI modules to avoid needing the actual library
module Fusuma
  module Libinput
    class Interface; end
    class Context; end
    module Functions; end

    module Constants
      GESTURE_EVENT_TYPE_RANGE = (800..807).freeze
    end

    class GestureEvent; end
  end
end

require "./lib/fusuma/plugin/inputs/libinput_ffi_input"

module Fusuma
  module Plugin
    module Inputs
      RSpec.describe LibinputFfiInput do
        let(:input) { described_class.new }

        describe "#tag" do
          it "returns underscored class name" do
            expect(input.tag).to eq("libinput_ffi_input")
          end
        end

        describe "#read_from_io" do
          it "reads length-prefixed Marshal data from pipe" do
            reader, writer = IO.pipe

            record = Events::Records::GestureRecord.new(
              status: "update",
              gesture: "swipe",
              finger: 3,
              delta: Events::Records::GestureRecord::Delta.new(
                1.0, -2.0, 1.5, -2.5, 1.0, 0.0
              )
            )

            data = Marshal.dump(record)
            writer.write([data.bytesize].pack("N"))
            writer.write(data)
            writer.flush

            allow(input).to receive(:io).and_return(reader)

            result = input.read_from_io
            expect(result).to be_a(Events::Records::GestureRecord)
            expect(result.gesture).to eq("swipe")
            expect(result.status).to eq("update")
            expect(result.finger).to eq(3)
            expect(result.delta.move_x).to eq(1.0)
            expect(result.delta.move_y).to eq(-2.0)

            reader.close
            writer.close
          end
        end

        describe "#io" do
          it "returns an IO object" do
            dummy_read = StringIO.new
            dummy_write = StringIO.new

            allow(input).to receive(:create_io).and_return([dummy_read, dummy_write])
            allow(input).to receive(:start_event_loop)

            expect(input.io).to eq(dummy_read)
          end
        end

        describe "#enabled?" do
          it "is disabled by default (opt-in while experimental)" do
            expect(input.enabled?).to be false
          end

          context "when enabled in config" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    libinput_ffi_input:
                      enabled: true
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { expect(input.enabled?).to be true }
          end
        end

        describe "#event_loop" do
          it "closes the writer when the loop dies so the reader sees EOF" do
            reader, writer = IO.pipe
            context = double("Context")
            allow(context).to receive(:io).and_raise("boom")
            input.instance_variable_set(:@context, context)
            allow(MultiLogger).to receive(:error)

            input.send(:event_loop, writer)

            expect(writer.closed?).to be true
            expect(reader.eof?).to be true
            reader.close
          end
        end

        describe "#process_event with DEVICE_ADDED" do
          let(:tap_fn) { double("TAP_SET_ENABLED") }
          let(:dwt_fn) { double("DWT_SET_ENABLED") }

          around do |example|
            ConfigHelper.load_config_yml = <<~CONFIG
              plugin:
                inputs:
                  libinput_ffi_input:
                    enabled: true
                    enable-tap: true
                    disable-dwt: true
            CONFIG

            example.run

            Config.custom_path = nil
          end

          before do
            stub_const("Fusuma::Libinput::Constants::DEVICE_ADDED", 1)
            stub_const("Fusuma::Libinput::Functions::EVENT_GET_TYPE", double(call: 1))
            stub_const("Fusuma::Libinput::Functions::EVENT_GET_DEVICE", double(call: :device_ptr))
            stub_const("Fusuma::Libinput::Functions::TAP_SET_ENABLED", tap_fn)
            stub_const("Fusuma::Libinput::Functions::DWT_SET_ENABLED", dwt_fn)
          end

          it "applies tap/dwt config to the added device" do
            expect(tap_fn).to receive(:call).with(:device_ptr, 1)
            expect(dwt_fn).to receive(:call).with(:device_ptr, 0)

            input.send(:process_event, :event_ptr, nil)
          end
        end

        describe "#process_event with touch/pointer events" do
          let(:writer) { StringIO.new }

          def written_record(writer)
            data = writer.string
            return nil if data.empty?

            length = data[0, 4].unpack1("N")
            Marshal.load(data[4, length]) # rubocop:disable Security/MarshalLoad
          end

          before do
            stub_const("Fusuma::Libinput::Constants::DEVICE_ADDED", 1)
            stub_const("Fusuma::Libinput::Constants::GESTURE_EVENT_TYPE_RANGE", 800..807)
            stub_const("Fusuma::Libinput::Constants::TOUCH_STATUS_MAP", {500 => "down"})
            stub_const("Fusuma::Libinput::Constants::POINTER_STATUS_MAP", {400 => "motion"})
            stub_const("Fusuma::Libinput::Functions::EVENT_GET_TYPE", double(call: event_type))
          end

          context "with TOUCH_DOWN (touch-events default)" do
            let(:event_type) { 500 }

            it "emits a TouchRecord" do
              touch_record = Events::Records::TouchRecord.new(
                status: "down", slot: 0, x_mm: 51.3, y_mm: 42.1
              )
              stub_const("Fusuma::Libinput::TouchEvent",
                double(new: double(to_touch_record: touch_record)))

              input.send(:process_event, :event_ptr, writer)

              record = written_record(writer)
              expect(record).to be_a(Events::Records::TouchRecord)
              expect(record.status).to eq("down")
            end
          end

          context "with POINTER_MOTION (pointer-events default)" do
            let(:event_type) { 400 }

            it "emits nothing (opt-in)" do
              input.send(:process_event, :event_ptr, writer)

              expect(writer.string).to be_empty
            end
          end

          context "with POINTER_MOTION and pointer-events: true" do
            let(:event_type) { 400 }

            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    libinput_ffi_input:
                      enabled: true
                      pointer-events: true
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it "emits a PointerRecord" do
              pointer_record = Events::Records::PointerRecord.new(
                status: "motion", dx: 2.0, dy: -1.0
              )
              stub_const("Fusuma::Libinput::PointerEvent",
                double(new: double(to_pointer_record: pointer_record)))

              input.send(:process_event, :event_ptr, writer)

              record = written_record(writer)
              expect(record).to be_a(Events::Records::PointerRecord)
              expect(record.dx).to eq(2.0)
            end
          end
        end

        describe "#process_event with DEVICE_ADDED and device: filter" do
          let(:send_events_fn) { double("SEND_EVENTS_SET_MODE") }
          let(:device_name) { "Awesome Touchpad" }
          let(:has_gesture) { 1 }

          around do |example|
            ConfigHelper.load_config_yml = <<~CONFIG
              plugin:
                inputs:
                  libinput_ffi_input:
                    enabled: true
                    device: Awesome
            CONFIG

            example.run

            Config.custom_path = nil
          end

          before do
            stub_const("Fusuma::Libinput::Constants::DEVICE_ADDED", 1)
            stub_const("Fusuma::Libinput::Constants::DEVICE_CAP_GESTURE", 5)
            stub_const("Fusuma::Libinput::Constants::SEND_EVENTS_DISABLED", 1)
            stub_const("Fusuma::Libinput::Functions::EVENT_GET_TYPE", double(call: 1))
            stub_const("Fusuma::Libinput::Functions::EVENT_GET_DEVICE", double(call: :device_ptr))
            stub_const("Fusuma::Libinput::Functions::DEVICE_GET_NAME",
              double(call: double(to_s: device_name)))
            stub_const("Fusuma::Libinput::Functions::DEVICE_HAS_CAPABILITY",
              double(call: has_gesture))
            stub_const("Fusuma::Libinput::Functions::SEND_EVENTS_SET_MODE", send_events_fn)
          end

          context "with a gesture device matching device:" do
            it "keeps the device enabled" do
              expect(send_events_fn).not_to receive(:call)

              input.send(:process_event, :event_ptr, nil)
            end
          end

          context "with a gesture device not matching device:" do
            let(:device_name) { "Other Touchpad" }

            it "disables events from the device" do
              expect(send_events_fn).to receive(:call).with(:device_ptr, 1)

              input.send(:process_event, :event_ptr, nil)
            end
          end

          context "with a non-gesture device (e.g. keyboard for dwt)" do
            let(:device_name) { "Some Keyboard" }
            let(:has_gesture) { 0 }

            it "keeps the device enabled" do
              expect(send_events_fn).not_to receive(:call)

              input.send(:process_event, :event_ptr, nil)
            end
          end
        end

        describe "lazy library loading" do
          # The plugin file is auto-required at boot by Plugin::Manager.
          # dlopen("libinput.so") must not run at require time, otherwise
          # fusuma cannot even boot on systems without libinput.
          it "does not dlopen libinput when the plugin is required" do
            require "open3"

            script = <<~RUBY
              require "fiddle"
              def Fiddle.dlopen(*)
                raise Fiddle::DLError, "dlopen disabled in this test"
              end
              require "fusuma/device"
              require "fusuma/plugin/inputs/libinput_ffi_input"
              puts "LAZY_OK"
            RUBY

            out, status = Open3.capture2e(RbConfig.ruby, "-I", File.expand_path("../../../../lib", __dir__), "-e", script)
            expect(status).to be_success, "expected require to succeed without libinput.so, got:\n#{out}"
            expect(out).to include("LAZY_OK")
          end
        end
      end
    end
  end
end
