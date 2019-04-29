require 'spec_helper'

module Fusuma
  module Plugin
    module Executors
      COMMAND_OPTIONS = { executors: { command_executor: 'command' } }.freeze

      class DummyVector < Fusuma::Plugin::Vectors::Vector
        def initialize(finger, direction)
          @finger = finger
          @direction = direction
        end
        attr_reader :finger, :direction
      end

      RSpec.describe CommandExecutor do
        let(:command_executor) { described_class.new(options) }
        let(:vector) { DummyVector.new('dummy_finger', 'dummy_direction') }
        let(:options) { { dummy: 'dummy_options' } }

        before do
          allow(YAML).to receive(:load_file) {
                           {
                             dummy: {
                               dummy_finger: {
                                 dummy_direction: {
                                   command: 'echo dummy'
                                 }
                               }
                             }
                           }
                         }
        end

        describe '#execute' do
          subject { command_executor.execute(vector) }
          it { is_expected.to be_truthy }
        end

        describe '#executable?' do
          subject { command_executor.executable?(vector) }

          context 'vector is matched with config file' do
            it { is_expected.to be_truthy }
          end

          context 'vector is matched with config file' do
            let(:vector) do
              DummyVector.new('invalid_finger', 'invalid_direction')
            end
            it { is_expected.to be_falsey }
          end
        end
      end
    end
  end
end
