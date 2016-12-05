require 'spec_helper'

describe Fusuma do
  it 'has a version number' do
    expect(Fusuma::VERSION).not_to be nil
  end

  context 'when without option' do
    it 'should not enable debug mode' do
      allow_any_instance_of(Fusuma::Runner).to receive(:read_libinput)
      multi_logger = Fusuma::MultiLogger.instance
      Fusuma::Runner.run
      expect(multi_logger).not_to be_debug_mode
    end
  end

  context 'when run with argument "-v"' do
    it 'should enable debug mode' do
      allow_any_instance_of(Fusuma::Runner).to receive(:read_libinput)
      multi_logger = Fusuma::MultiLogger.instance
      Fusuma::Runner.run(v: true)
      expect(multi_logger).to be_debug_mode
    end
  end
end
