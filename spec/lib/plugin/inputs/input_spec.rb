require 'spec_helper'
require './lib/fusuma/plugin/inputs/input.rb'

module Fusuma
  module Plugin
    module Inputs
      DUMMY_OPTIONS = { inputs: { dummy_input: 'dummy' } }.freeze

      class DummyInput < Input
      end

      RSpec.describe DummyInput do
        let(:dummy_input) { described_class.new }

        describe 'run' do
          subject { dummy_input.run { |e| return e } }
          it { is_expected.to be_a Formats::Event }
        end
      end

      RSpec.describe Generator do
        let(:options) { DUMMY_OPTIONS }
        let(:generator) { described_class.new(options: options) }

        before do
          allow(generator).to receive(:plugins) { [DummyInput] }
        end

        describe '#generate' do
          subject { generator.generate }

          it { is_expected.to be_a_kind_of(Array) }

          it 'generate plugins have options' do
            expect(subject.any?(&:options)).to be true
          end

          it 'have a DummyInput' do
            expect(subject.first).to be_a_kind_of DummyInput
          end

          it 'have only a input options' do
            expect(subject.first.options).to eq DUMMY_OPTIONS[:inputs][:dummy_input]
          end
        end
      end
    end
  end
end
