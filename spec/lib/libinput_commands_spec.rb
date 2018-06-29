require 'spec_helper'
module Fusuma
  describe LibinputCommands do
    let(:libinput_commands) { described_class.new }
    describe '#version' do
      subject { libinput_commands.version }

      context 'when libinput-list-device is available' do
        before do
          allow(libinput_commands).to receive('which')
            .with('libinput') { false }
          allow(libinput_commands).to receive('which')
            .with('libinput-list-devices') { true }
          allow_any_instance_of(Kernel).to receive(:`)
            .with('libinput-list-devices --version') { "1.6.3\n" }
        end

        it { is_expected.to eq '1.6.3' }
        it { expect(libinput_commands.new_cli_option_available?).to be false }
      end

      context 'when libinput is available' do
        before do
          allow(libinput_commands).to receive('which')
            .with('libinput') { true }
          allow(libinput_commands).to receive('which')
            .with('libinput-list-devices') { false }
          allow_any_instance_of(Kernel).to receive(:`)
            .with('libinput --version') { "1.8\n" }
        end

        it { is_expected.to eq '1.8' }
        it { expect(libinput_commands.new_cli_option_available?).to be true }
      end

      context 'when libinput command is not found' do
        before do
          allow(libinput_commands).to receive('which')
            .with('libinput') { false }
          allow(libinput_commands).to receive('which')
            .with('libinput-list-devices') { false }
        end

        it 'shold print error and exit 1' do
          expect(MultiLogger).to receive(:error)
          expect { subject }.to raise_error(SystemExit)
        end
      end
    end

    describe '#new_cli_option_available?' do
      subject { libinput_commands.new_cli_option_available? }
      context 'with NEW_CLI_OPTION_VERSION' do
        before do
          allow(libinput_commands).to receive(:version)
            .and_return(LibinputCommands::NEW_CLI_OPTION_VERSION)
        end
        it { is_expected.to eq true }
      end
      context 'without NEW_CLI_OPTION_VERSION' do
        before do
          allow(libinput_commands).to receive(:version)
            .and_return(LibinputCommands::NEW_CLI_OPTION_VERSION - 0.1)
        end
        it { is_expected.to eq false }
      end
    end

    describe 'list_devices' do
      subject { libinput_commands.list_devices }
      after { subject }

      context 'with new cli version' do
        before do
          allow(libinput_commands).to receive(:new_cli_option_available?)
            .and_return(true)
        end

        it 'call `libinput list-devices`' do
          command = 'libinput list-devices'
          expect(Open3).to receive(:popen3)
            .with(command)
        end
      end
      context 'with old cli version' do
        before do
          allow(libinput_commands).to receive(:new_cli_option_available?)
            .and_return(false)
        end

        it 'call `libinput-list-devices`' do
          command = 'libinput-list-devices'
          expect(Open3).to receive(:popen3)
            .with(command)
        end
      end
    end

    describe 'debug_events' do
      subject { libinput_commands.debug_events }

      before do
        allow(libinput_commands).to receive(:device_option)
          .and_return('--device stub_device')
      end

      after { subject }

      context 'with new cli version' do
        before do
          allow(libinput_commands).to receive(:new_cli_option_available?)
            .and_return(true)
        end

        it 'call `libinput debug-events`' do
          command = 'libinput debug-events'
          expect(Open3).to receive(:popen3)
            .with("stdbuf -oL -- #{command} --device stub_device")
            .and_return 'stub message'
        end
      end

      context 'with old cli version' do
        before do
          allow(libinput_commands).to receive(:new_cli_option_available?)
            .and_return(false)
        end

        it 'call `libinput-debug-events`' do
          command = 'libinput-debug-events'
          expect(Open3).to receive(:popen3)
            .with("stdbuf -oL -- #{command} --device stub_device")
            .and_return 'stub message'
        end
      end
    end
  end
end
