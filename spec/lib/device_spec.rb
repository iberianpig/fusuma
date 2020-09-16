# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/device.rb'
require './lib/fusuma/plugin/inputs/libinput_command_input.rb'

module Fusuma
  RSpec.describe Device do
    describe '.all' do
      it 'should fetch all devices'
    end

    describe '.reset' do
      it 'should clear all cache'
    end

    describe '.available' do
      let(:libinput_device_command) { 'libinput list-devices' }

      before do
        Device.reset
        @dummy_io = StringIO.new('dummy')
        allow(Process).to receive(:waitpid).and_return(nil)

        allow(POSIX::Spawn).to receive(:popen4)
          .with(libinput_device_command)
          .and_return([nil, @dummy_io, list_devices_output, @dummy_io])
      end

      context 'with XPS-9360 (have a correct device)' do
        let(:list_devices_output) do
          File.open('./spec/lib/libinput-list-devices_iberianpig-XPS-9360.txt')
        end

        it { expect(Device.available).to be_a Array }
        it { expect(Device.available.map(&:name)).not_to include 'Power Button' }
        it { expect(Device.available.map(&:name)).to include 'DLL075B:01 06CB:76AF Touchpad' }
      end

      context 'with no tap to click device (like a bluetooth apple trackpad)' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_magic_trackpad.txt')
        end

        it { expect(Device.available).to be_a Array }
        it { expect(Device.available.map(&:name)).to eq ['Christopher’s Trackpad', 'bcm5974'] }
      end

      context "context with the device's name not found at first line" do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_thejinx0r.txt')
        end

        it { expect(Device.available).to be_a Array }
        it { expect(Device.available.map(&:name)).to include 'HTX USB HID Device HTX HID Device Touchpad' }
      end

      context 'when no devices' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_unavailable.txt')
        end

        it 'should failed with exit' do
          expect { Device.available }.to raise_error(SystemExit)
        end

        it 'should failed with printing error log' do
          expect(MultiLogger).to receive(:error)
          expect { Device.available }.to raise_error(SystemExit)
        end
      end
    end
  end
end
