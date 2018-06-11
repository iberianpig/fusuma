require 'spec_helper'

module Fusuma
  describe Runner do
    describe '.run' do
      before do
        Singleton.__init__(Fusuma::MultiLogger)
        Singleton.__init__(Fusuma::Config)
      end

      context 'when without option' do
        it 'should not enable debug mode' do
          allow_any_instance_of(Fusuma::Runner).to receive(:run)
          Fusuma::Runner.run
          expect(Fusuma::MultiLogger.instance).not_to be_debug_mode
        end
      end

      context 'when run with argument "-v"' do
        it 'should enable debug mode' do
          allow_any_instance_of(Fusuma::Runner).to receive(:run)
          Fusuma::MultiLogger.send(:new)
          Fusuma::Runner.run(verbose: true)
          expect(Fusuma::MultiLogger.instance).to be_debug_mode
        end
      end

      context 'when run with argument "-c path/to/config.yml"' do
        it 'should assign custom_path' do
          allow_any_instance_of(Fusuma::Runner).to receive(:run)
          config = Fusuma::Config.instance
          expect { Fusuma::Runner.run(config_path: 'path/to/config.yml') }
            .to change { config.custom_path }.from(nil).to('path/to/config.yml')
        end
      end
    end
  end
end
