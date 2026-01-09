# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/device"
require "./lib/fusuma/plugin/inputs/libinput_command_input"

module Fusuma
  RSpec.describe Device do
    describe ".all" do
      it "should fetch all devices"
    end

    describe ".reset" do
      let(:libinput_device_command) { "dummy-libinput-list-devices" }
      let(:list_devices_output) do
        File.open("./spec/fusuma/libinput-list-devices_iberianpig-XPS-9360.txt")
      end

      before do
        Device.reset
        allow_any_instance_of(LibinputCommand)
          .to receive(:list_devices_command)
          .and_return(libinput_device_command)

        dummy_io = StringIO.new("dummy")
        dummy_status = double("Process::Status", success?: true)
        allow(Open3).to receive(:capture3)
          .with(libinput_device_command)
          .and_return([list_devices_output, dummy_io, dummy_status])
      end

      after do
        Device.reset
      end

      it "should clear @all cache" do
        Device.all
        expect(Device.instance_variable_get(:@all)).not_to be_nil
        Device.reset
        expect(Device.instance_variable_get(:@all)).to be_nil
      end

      it "should clear @available cache" do
        Device.available
        expect(Device.instance_variable_get(:@available)).not_to be_nil
        Device.reset
        expect(Device.instance_variable_get(:@available)).to be_nil
      end

      it "should clear @previous_device_ids" do
        Device.all
        expect(Device.instance_variable_get(:@previous_device_ids)).not_to be_nil
        Device.reset
        expect(Device.instance_variable_get(:@previous_device_ids)).to be_nil
      end

      it "should log devices again after reset" do
        Device.all
        Device.reset

        expect(MultiLogger).to receive(:debug).with(hash_including(:detected_devices))
        Device.all
      end
    end

    describe ".available" do
      let(:libinput_device_command) { "dummy-libinput-list-devices" }

      before do
        Device.reset
        allow_any_instance_of(LibinputCommand)
          .to receive(:list_devices_command)
          .and_return(libinput_device_command)

        dummy_io = StringIO.new("dummy")
        dummy_status = double("Process::Status", success?: true)
        allow(Open3).to receive(:capture3)
          .with(libinput_device_command)
          .and_return([list_devices_output, dummy_io, dummy_status])
      end

      after do
        Device.reset
      end

      context "with XPS-9360 (have a correct device)" do
        let(:list_devices_output) do
          File.open("./spec/fusuma/libinput-list-devices_iberianpig-XPS-9360.txt")
        end

        it { expect(Device.available).to be_a Array }
        it { expect(Device.available.map(&:name)).not_to include "Power Button" }
        it { expect(Device.available.map(&:name)).to include "DLL075B:01 06CB:76AF Touchpad" }
      end

      context "with no tap to click device (like a bluetooth apple trackpad)" do
        let(:list_devices_output) do
          File.open("spec/fusuma/libinput-list-devices_magic_trackpad.txt")
        end

        it { expect(Device.available).to be_a Array }
        it { expect(Device.available.map(&:name)).to eq ["Christopher’s Trackpad", "bcm5974"] }
      end

      context "context with the device's name not found at first line" do
        let(:list_devices_output) do
          File.open("spec/fusuma/libinput-list-devices_thejinx0r.txt")
        end

        it { expect(Device.available).to be_a Array }
        it { expect(Device.available.map(&:name)).to include "HTX USB HID Device HTX HID Device Touchpad" }
      end

      context "when no devices" do
        let(:list_devices_output) do
          File.open("spec/fusuma/libinput-list-devices_unavailable.txt")
        end

        it "should return empty array" do
          expect(Device.available).to eq []
        end

        it "should print warning log" do
          expect(MultiLogger).to receive(:warn).with("Touchpad is not found")
          Device.available
        end
      end

      context "with some device has same names" do
        let(:list_devices_output) do
          File.open("spec/fusuma/libinput-list-devices_razer_razer_blade.txt")
        end

        it { expect(Device.available).to be_a Array }
        it "should have capabilities" do
          razer_devices = Device.all.group_by(&:name)["Razer Razer Blade"]
          expect(razer_devices.size).to eq 3
        end

        it "should know capabilities" do
          razer_devices = Device.all.group_by(&:name)["Razer Razer Blade"]
          capabilities = razer_devices.map(&:capabilities)
          expect(capabilities).to eq ["keyboard", "keyboard pointer", "pointer"]
          keyboard_devices = razer_devices.select { |d| d.capabilities == "keyboard" }
          expect(keyboard_devices.size).to eq 1
        end
      end
    end
  end
end
