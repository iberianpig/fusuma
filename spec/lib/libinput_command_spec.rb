# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/libinput_command.rb'

module Fusuma
  RSpec.describe LibinputCommand do
    let(:libinput_command) { described_class.new(libinput_options: libinput_options, commands: commands) }
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
      subject { libinput_command.list_devices {} }
      after { subject }

      before do
        dummy_io = StringIO.new('dummy')
        io = StringIO.new('dummy output')
        allow(POSIX::Spawn).to receive(:popen4).with(anything).and_return([nil, dummy_io, io, dummy_io])
        allow(Process).to receive(:waitpid).and_return(nil)
      end

      context 'with the alternative command' do
        let(:commands) { { list_devices_command: 'dummy_list_devices' } }

        it 'should call dummy events' do
          expect(POSIX::Spawn).to receive(:popen4).with(/dummy_list_devices/)
        end
      end

      context 'with new cli version' do
        before do
          allow(libinput_command).to receive(:new_cli_option_available?)
            .and_return(true)
        end

        it 'call `libinput list-devices`' do
          command = 'libinput list-devices'
          expect(POSIX::Spawn).to receive(:popen4)
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
          expect(POSIX::Spawn).to receive(:popen4)
            .with(command)
        end
      end
    end

    describe 'debug_events' do
      subject { libinput_command.debug_events }
      before do
        dummy_io = StringIO.new('dummy')
        allow(POSIX::Spawn).to receive(:popen4).with(anything).and_return([nil, dummy_io, dummy_io, dummy_io])
      end

      context 'with the alternative command' do
        let(:commands) { { debug_events_command: 'dummy_debug_events' } }

        it 'should call dummy events' do
          expect(POSIX::Spawn).to receive(:popen4).with(/dummy_debug_events/).once
          subject
        end
      end

      context 'with new cli version' do
        before do
          allow(libinput_command)
            .to receive(:new_cli_option_available?)
            .and_return(true)
        end

        it 'should call `libinput debug-events`' do
          command = 'libinput debug-events'
          expect(POSIX::Spawn).to receive(:popen4)
            .with("stdbuf -oL -- #{command}")
          subject
        end
      end

      context 'with old cli version' do
        before do
          allow(libinput_command)
            .to receive(:new_cli_option_available?)
            .and_return(false)
        end

        it 'should call `libinput-debug-events`' do
          command = 'libinput-debug-events'
          expect(POSIX::Spawn).to receive(:popen4)
            .with("stdbuf -oL -- #{command}")
          subject
        end
      end
    end
  end
end
