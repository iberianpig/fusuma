require 'spec_helper'
require './lib/fusuma/plugin/parsers/parser.rb'
require './lib/fusuma/plugin/formats/event_format.rb'

module Fusuma
  module Plugin
    module Parsers
      DUMMY_OPTIONS = { parsers: { dummy_parser: 'dummy' } }.freeze

      class DummyParser < Parser
        DEFAULT_SOURCE = 'dummy_input'.freeze
      end

      RSpec.describe Parser do
        let(:options) { DUMMY_OPTIONS }
        let(:parser) { DummyParser.new(options: options) }

        describe '#source' do
          subject { parser.source }

          it { is_expected.to be DummyParser::DEFAULT_SOURCE }
        end

        describe '#parse' do
          subject { parser.parse(event) }
          let(:event) { Formats::Event.new(tag: 'dummy_input', record: 'dummy') }

          it { is_expected.to be event }
        end
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
