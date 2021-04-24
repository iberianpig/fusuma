# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/libinput_command'

module Fusuma
  RSpec.describe LibinputCommand do
    let(:libinput_command) do
      described_class.new(libinput_options: libinput_options, commands: commands)
    end
    let(:libinput_options) { [] }
    let(:commands) { {} }
    describe '#version' do
      subject { libinput_command.version }

      context 'when libinput-list-device is available' do
        before do
          allow(libinput_command).to receive('which')
            .with('libinput') { false }
          allow(libinput_command).to receive('which')
            .with('libinput-list-devices') { true }
          allow_any_instance_of(Kernel).to receive(:`)
            .with('libinput-list-devices --version') { "1.6.3\n" }
        end

        it { is_expected.to eq '1.6.3' }
        it { expect(libinput_command.new_cli_option_available?).to be false }
      end

      context 'when libinput is available' do
        before do
          allow(libinput_command).to receive('which')
            .with('libinput') { true }
          allow(libinput_command).to receive('which')
            .with('libinput-list-devices') { false }
          allow_any_instance_of(Kernel).to receive(:`)
            .with('libinput --version') { "1.8\n" }
        end

        it { is_expected.to eq '1.8' }
        it { expect(libinput_command.new_cli_option_available?).to be true }
      end

      context 'when libinput command is not found' do
        before do
          allow(libinput_command).to receive('which')
            .with('libinput') { false }
          allow(libinput_command).to receive('which')
            .with('libinput-list-devices') { false }
        end

        it 'shold print error and exit 1' do
          expect(MultiLogger).to receive(:error)
          expect { subject }.to raise_error(SystemExit)
        end
      end
    end

    describe '#new_cli_option_available?' do
      subject { libinput_command.new_cli_option_available? }
      context 'with NEW_CLI_OPTION_VERSION' do
        before do
          allow(libinput_command).to receive(:version)
            .and_return(LibinputCommand::NEW_CLI_OPTION_VERSION)
        end
        it { is_expected.to eq true }
      end
      context 'without NEW_CLI_OPTION_VERSION' do
        before do
          allow(libinput_command).to receive(:version)
            .and_return(LibinputCommand::NEW_CLI_OPTION_VERSION - 0.1)
        end
        it { is_expected.to eq false }
      end
    end

    describe 'list_devices' do
      subject { libinput_command.list_devices }
      after { subject }

      before do
        dummy_io = StringIO.new('dummy')
        io = StringIO.new('dummy output')
        allow(Open3).to receive(:popen3).with(anything).and_return([dummy_io, io, dummy_io,
                                                                    dummy_io, nil])
      end

      context 'with the alternative command' do
        let(:commands) { { list_devices_command: 'dummy_list_devices' } }

        it 'should call dummy events' do
          expect(Open3).to receive(:popen3).with(/dummy_list_devices/)
        end
      end

      context 'with new cli version' do
        before do
          allow(libinput_command).to receive(:new_cli_option_available?)
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
          allow(libinput_command).to receive(:new_cli_option_available?)
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
      before do
        @dummy_io = StringIO.new('dummy')
        allow(Process).to receive(:detach).with(anything).and_return(nil)
      end
      subject { libinput_command.debug_events(@dummy_io) }

      context 'with the alternative command' do
        before do
          allow(libinput_command).to receive(:debug_events_with_options).and_return 'dummy_debug_events'
        end

        it 'should call dummy events' do
          expect(Process).to receive(:spawn).with('dummy_debug_events',
                                                  { out: @dummy_io, in: '/dev/null' }).once
          subject
        end
      end
    end

    describe '#debug_events_with_options' do
      subject { libinput_command.debug_events_with_options }

      context 'with new cli version' do
        before do
          allow(libinput_command)
            .to receive(:new_cli_option_available?)
            .and_return(true)
        end
        it { is_expected.to eq 'stdbuf -oL -- libinput debug-events' }
      end

      context 'with old cli version' do
        before do
          allow(libinput_command)
            .to receive(:new_cli_option_available?)
            .and_return(false)
        end
        it { is_expected.to eq 'stdbuf -oL -- libinput-debug-events' }
      end
    end
  end
end
