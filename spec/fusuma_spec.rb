require 'spec_helper'

module Fusuma
  describe Runner do
    describe '.run' do
      before do
        Singleton.__init__(MultiLogger)
        Singleton.__init__(Config)
      end

      context 'when without option' do
        it 'should not enable debug mode' do
          allow_any_instance_of(Runner).to receive(:run)
          Runner.run
          expect(MultiLogger.instance).not_to be_debug_mode
        end
      end

      context 'when run with argument "-v"' do
        it 'should enable debug mode' do
          allow_any_instance_of(Runner).to receive(:run)
          allow_any_instance_of(LibinputCommands).to receive(:version)
            .and_return("test version\n")
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
