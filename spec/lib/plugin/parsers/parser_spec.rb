require 'spec_helper'
module Fusuma
  module Plugin
    module Parsers
      DUMMY_OPTIONS = { parsers: { dummy_parser: 'dummy' } }.freeze

      class DummyParser < Parser
        DEFAULT_SOURCE = 'dummy_input'.freeze
      end

      RSpec.describe Parser do
      end

      RSpec.describe Generator do
        let(:options) { DUMMY_OPTIONS }
        let(:generator) { described_class.new(options: options) }

        before do
          allow(generator).to receive(:plugins) { [DummyParser] }
        end

        describe '#generate' do
          subject { generator.generate }

          it { is_expected.to be_a_kind_of(Array) }

          it 'generate plugins have options' do
            expect(subject.any?(&:options)).to be true
          end

          it 'have a DummyParser' do
            expect(subject.first).to be_a_kind_of DummyParser
          end

          it 'have only a parser options' do
            expect(subject.first.options).to eq DUMMY_OPTIONS[:parsers][:dummy_parser]
          end
        end
      end
    end
  end
end
