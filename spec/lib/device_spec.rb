require 'spec_helper'
module Fusuma
  describe Device do
    describe '.ids' do
      subject { Device.ids }
      let(:libinput_device_command) { 'libinput list-devices' }

      before do
        Device.reset
        allow_any_instance_of(Inputs::LibinputCommandInput)
          .to receive(:list_devices_command)
          .and_return(libinput_device_command)
        allow(Open3).to receive(:popen3)
          .with(libinput_device_command)
          .and_yield(nil, list_devices_output, nil, nil)
      end

      context 'with XPS-9360 (have a correct device)' do
        let(:list_devices_output) do
          File.open('./spec/lib/libinput-list-devices_iberianpig-XPS-9360.txt')
        end

        it { is_expected.to be_a Array }
        it { is_expected.to eq %w[event14] }
      end

      context 'with no tap to click device (like a bluetooth apple trackpad)' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_magic_trackpad.txt')
        end

        it { is_expected.to be_a Array }
        it { is_expected.to eq %w[event8 event9] }
      end

      context 'when no devices' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_unavailable.txt')
        end

        it 'should failed with exit' do
          expect { subject }.to raise_error(SystemExit)
        end

        it 'should failed with printing error log' do
          expect(MultiLogger).to receive(:error)
          expect { subject }.to raise_error(SystemExit)
        end
      end
    end

    describe '.names' do
      subject { Device.names }
      let(:libinput_device_command) { 'libinput list-devices' }

      before do
        Device.reset
        allow_any_instance_of(Inputs::LibinputCommandInput)
          .to receive(:list_devices_command)
          .and_return(libinput_device_command)
        allow(Open3).to receive(:popen3)
          .with(libinput_device_command)
          .and_yield(nil, list_devices_output, nil, nil)
      end

      context 'with XPS-9360 (have a correct device)' do
        let(:list_devices_output) do
          File.open('./spec/lib/libinput-list-devices_iberianpig-XPS-9360.txt')
        end

        it { is_expected.to be_a Array }
        it { is_expected.to eq ['DLL075B:01 06CB:76AF Touchpad'] }
      end

      context 'with no tap to click device (like a bluetooth apple trackpad)' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_magic_trackpad.txt')
        end

        it { is_expected.to be_a Array }
        it { is_expected.to eq ['Christopher’s Trackpad', 'bcm5974'] }
      end

      context 'when no devices' do
        let(:list_devices_output) do
          File.open('spec/lib/libinput-list-devices_unavailable.txt')
        end

        it 'should failed with exit' do
          expect { subject }.to raise_error(SystemExit)
        end

        it 'should failed with printing error log' do
          expect(MultiLogger).to receive(:error)
          expect { subject }.to raise_error(SystemExit)
        end
      end
    end
  end
end
