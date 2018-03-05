require 'spec_helper'
module Fusuma
  describe 'Device' do
    describe '.name' do
      before { Device.names = nil }
      context 'with no tap to click device (like a bluetooth apple trackpad)' do
        let(:magic_trackpad_log) do
          File.open('spec/lib/libinput-list-devices_magic_trackpad.txt')
        end
        it 'should return array' do
          allow(Open3).to receive(:popen3).with('libinput-list-devices')
            .and_return(magic_trackpad_log)
          expect(Device.names.class).to eq Array
        end

        it 'should return correct devices' do
          allow(Open3).to receive(:popen3).with('libinput-list-devices')
            .and_return(magic_trackpad_log)
          expect(Device.names).to eq %w(event8 event9)
        end
      end

      context 'when no devices' do
        let(:unavailable_log) do
          File.open('spec/lib/libinput-list-devices_unavailable.txt')
        end

        it 'should failed with exit' do
          allow(Open3).to receive(:popen3).with('libinput-list-devices')
            .and_return(unavailable_log)
          expect { Device.names }.to raise_error(SystemExit)
        end

        it 'should failed with printing error log' do
          allow(Open3).to receive(:popen3).with('libinput-list-devices')
            .and_return(unavailable_log)
          expect(MultiLogger).to receive(:error)
          expect { Device.names }.to raise_error(SystemExit)
        end
      end
    end
  end
end
