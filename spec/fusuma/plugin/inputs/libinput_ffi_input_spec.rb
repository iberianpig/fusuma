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
