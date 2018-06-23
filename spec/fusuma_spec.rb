require 'spec_helper'

module Fusuma
  describe Runner do
    describe '.run' do
      before do
        Singleton.__init__(MultiLogger)
        Singleton.__init__(Config)
        allow_any_instance_of(Runner).to receive(:run)
        allow_any_instance_of(LibinputCommands).to receive(:version)
          .and_return("test version\n")
      end

      context 'when without option' do
        it 'should not enable debug mode' do
          expect(MultiLogger.instance).not_to be_debug_mode
          Runner.run
        end
      end

      context 'when run with argument "--version"' do
        it 'should print version' do
          expect(MultiLogger).to receive(:info)
            .with('---------------------------------------------')
          expect(MultiLogger).to receive(:info)
            .with("Fusuma: #{Fusuma::VERSION}")
          expect(MultiLogger).to receive(:info)
            .with("libinput: #{LibinputCommands.new.version}")
          expect(MultiLogger).to receive(:info)
            .with("OS: #{`uname -rsv`}".strip)
          expect(MultiLogger).to receive(:info)
            .with("Distribution: #{`cat /etc/issue`}".strip)
          expect(MultiLogger).to receive(:info)
            .with("Desktop session: #{`echo $DESKTOP_SESSION`}".strip)
          expect(MultiLogger).to receive(:info)
            .with('---------------------------------------------')
          Runner.run(version: true)
        end
      end

      context 'when run with argument "-l"' do
        it 'should print device list' do
          allow(Device).to receive(:names) { %w[test_device1 test_device2] }
          expect { Runner.run(list: true) }.to raise_error(SystemExit)
            .and output("test_device1\ntest_device2\n").to_stdout
        end
      end

      context 'when run with argument "--device="test_device2"' do
        it 'should set device' do
          allow(Device).to receive(:names) { %w[test_device1 test_device2] }
          expect(Device).to receive(:given_device=).with('test_device2')
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
        it 'should assign custom_path' do
          allow_any_instance_of(Runner).to receive(:run)
          config = Config.instance
          expect { Runner.run(config_path: 'path/to/config.yml') }
            .to change { config.custom_path }.from(nil).to('path/to/config.yml')
        end
      end
    end
  end
end
