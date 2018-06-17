require 'spec_helper'
module Fusuma
  describe Device do
    describe '.name' do
      before do
        Device.names = nil
        allow_any_instance_of(LibinputCommands)
          .to receive(:list_devices_command)
          .and_return(libinput_device_command)
        allow(Open3).to receive(:popen3)
          .with(libinput_device_command)
          .and_yield(nil, list_devices_output, nil, nil)
      end
      let(:libinput_device_command) { 'libinput list-devices' }

      context 'with no tap to click device (like a bluetooth apple trackpad)' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_magic_trackpad.txt')
        end

        it 'should return array' do
          expect(Device.names.class).to eq Array
        end

        it 'should return correct devices' do
          expect(Device.names).to eq %w[event8 event9]
        end
      end

      context 'when no devices' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_unavailable.txt')
        end

        it 'should failed with exit' do
          expect { Device.names }.to raise_error(SystemExit)
        end

        it 'should failed with printing error log' do
          expect(MultiLogger).to receive(:error)
          expect { Device.names }.to raise_error(SystemExit)
        end
      end
    end
  end
end
