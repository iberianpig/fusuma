require 'spec_helper'

module Fusuma
  module Plugin
    module Executors
      DUMMY_OPTIONS = { executors: { dummy_executor: 'dummy' } }.freeze

      class DummyExecutor < Executor
        DEFAULT_SOURCE = 'dummy'.freeze
        def execute(event)
          puts event.record
        end
      end

      RSpec.describe DummyExecutor do
        let(:dummy_executor) { described_class.new(options) }
        let(:options) { {} }

        describe '#execute' do
          subject { dummy_executor.execute(dummy_event) }
          let(:dummy_event) { Formats::Event.new(tag: 'dummy', record: 'dummy') }
          it { expect { subject }.to output("dummy\n").to_stdout }
        end

        describe '#executable?' do
          subject { dummy_executor.executable?(dummy_event) }

          context 'event source is matched with tag' do
            let(:dummy_event) { Formats::Event.new(tag: 'dummy', record: 'dummy') }
            it { is_expected.to be true }
          end

          context 'event source is NOT matched with tag' do
            let(:dummy_event) { Formats::Event.new(tag: 'INVALID_TAG', record: 'dummy') }
            it { is_expected.to be false }
          end
        end

        describe '#source' do
          subject { dummy_executor.source }

          it { is_expected.to be DummyExecutor::DEFAULT_SOURCE }

          context 'with source option' do
            let(:options) { { source: 'awesome_source' } }
            it { is_expected.to eq 'awesome_source' }
          end
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
