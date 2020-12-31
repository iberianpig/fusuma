# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma.rb'
require './lib/fusuma/plugin/inputs/libinput_command_input.rb'
require './lib/fusuma/plugin/filters/libinput_device_filter.rb'

module Fusuma
  RSpec.describe Runner do
    describe '.run' do
      before do
        Singleton.__init__(MultiLogger)
        Singleton.__init__(Config)
        allow_any_instance_of(Runner).to receive(:run)
        allow_any_instance_of(LibinputCommand).to receive(:version)
          .and_return("1.8\n")
      end

      context 'when without option' do
        it 'should not enable debug mode' do
          expect(MultiLogger.instance).not_to be_debug_mode
          Runner.run
        end
      end

      context 'when run with argument "--version"' do
        # NOTE: skip print reload config message
        before { allow(MultiLogger).to receive(:info).with(anything) }
        it 'should print version' do
          expect(MultiLogger).to receive(:info)
            .with("Fusuma: #{Fusuma::VERSION}")
          expect(MultiLogger).to receive(:info)
            .with("libinput: #{LibinputCommand.new.version}")
          expect(MultiLogger).to receive(:info)
            .with("OS: #{`uname -rsv`}".strip)
          expect(MultiLogger).to receive(:info)
            .with("Distribution: #{`cat /etc/issue`}".strip)
          expect(MultiLogger).to receive(:info)
            .with("Desktop session: #{`echo $DESKTOP_SESSION $XDG_SESSION_TYPE`}".strip)
          expect { Runner.run(version: true) }.to raise_error(SystemExit)
        end
      end

      context 'when run with argument "-l"' do
        it 'should print device list' do
          allow(Device).to receive(:available) {
                             [Device.new(name: 'test_device1'),
                              Device.new(name: 'test_device2')]
                           }
          expect { Runner.run(list: true) }.to raise_error(SystemExit)
            .and output("test_device1\ntest_device2\n").to_stdout
        end
      end

      # TODO: remove from_option and command line options
      context 'when run with argument "--device="test_device2"' do
        it 'should set device' do
          allow(Device).to receive(:names) { %w[test_device1 test_device2] }
          expect(Plugin::Filters::LibinputDeviceFilter::KeepDevice)
            .to receive(:from_option=).with('test_device2')
          Runner.run(device: 'test_device2')
        end
      end

      context 'when run with argument "-v"' do
        it 'should enable debug mode' do
          MultiLogger.send(:new)
          Runner.run(verbose: true)
          expect(MultiLogger.instance).to be_debug_mode
        end
      end

      context 'when run with argument "-c path/to/config.yml"' do
        before do
          allow_any_instance_of(Runner).to receive(:run)
          @config = Config.instance

          string = <<~CONFIG
            swipe:
              3:
                left:
                  command: echo 'swipe left'

          CONFIG
          @file_path = Tempfile.open do |temp_file|
            temp_file.tap { |f| f.write(string) }
          end
        end
        it 'should assign custom_path' do
          expect { Runner.run(config_path: @file_path) }
            .to change { @config.custom_path }.from(nil).to(@file_path)
        end
      end
    end
  end
end
