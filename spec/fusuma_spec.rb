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
          allow_any_instance_of(Fusuma::Runner).to receive(:read_libinput)
          Fusuma::Runner.run
          expect(Fusuma::MultiLogger.instance).not_to be_debug_mode
        end
      end

      context 'when run with argument "-v"' do
        it 'should enable debug mode' do
          allow_any_instance_of(Fusuma::Runner).to receive(:read_libinput)
          Fusuma::MultiLogger.send(:new)
          Fusuma::Runner.run(verbose: true)
          expect(Fusuma::MultiLogger.instance).to be_debug_mode
        end
      end

      context 'when run with argument "-c path/to/config.yml"' do
        it 'should assign custom_path' do
          allow_any_instance_of(Fusuma::Runner).to receive(:read_libinput)
          config = Fusuma::Config.instance
          Fusuma::Runner.run(config: 'path/to/config.yml')
          expect(config.custom_path).to eq 'path/to/config.yml'
        end
      end
    end
  end
end
