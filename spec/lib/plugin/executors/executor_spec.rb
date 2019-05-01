require 'spec_helper'
require_relative './dummy_vector.rb'

module Fusuma
  module Plugin
    module Executors
      DUMMY_OPTIONS = { executors: { dummy_executor: 'dummy' } }.freeze

      RSpec.describe Executor do
        let(:executor) { described_class.new }

        describe '#execute' do
          subject { executor.execute('dummy') }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end

        describe '#executable?' do
          subject { executor.executable?('dummy') }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end
      end

      class DummyExecutor < Executor
        def execute(vector)
          puts vector.direction
        end

        def executable?(vector)
          vector.to_s
        end
      end

      RSpec.describe DummyExecutor do
        let(:dummy_executor) { described_class.new(options) }
        let(:vector) { Vectors::DummyVector.new('dummy_finger', 'dummy_direction') }
        let(:options) { {} }

        describe '#execute' do
          subject { dummy_executor.execute(vector) }
          it { expect { subject }.to output("dummy_direction\n").to_stdout }
        end

        describe '#executable?' do
          subject { dummy_executor.executable?(vector) }
          it { is_expected.to be_truthy }
        end
      end

      RSpec.describe Generator do
        let(:options) { DUMMY_OPTIONS }
        let(:generator) { described_class.new(options: options) }

        before do
          allow(generator).to receive(:plugins) { [DummyExecutor] }
        end

        describe '#generate' do
          subject { generator.generate }

          it { is_expected.to be_a_kind_of(Array) }

          it 'generate plugins have options' do
            expect(subject.any?(&:options)).to be true
          end

          it 'have a DummyExecutor' do
            expect(subject.first).to be_a_kind_of DummyExecutor
          end

          it 'have only a executor options' do
            expect(subject.first.options).to eq DUMMY_OPTIONS[:executors][:dummy_executor]
          end
        end
      end
    end
  end
end
