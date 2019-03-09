require 'spec_helper'

module Fusuma
  module Plugin
    module Formats
      DUMMY_OPTIONS = { formats: { dummy_format: 'dummy' } }.freeze

      class DummyFormat < Format
      end

      RSpec.describe Format do
        let(:format) { DummyFormat.new }

        describe '#type' do
          subject { format.type }
          it { is_expected.to eq 'dummy' }
        end
      end

      RSpec.describe Generator do
        let(:options) { DUMMY_OPTIONS }
        let(:generator) { described_class.new(options: options) }

        before do
          allow(generator).to receive(:plugins) { [DummyFormat] }
        end

        describe '#generate' do
          subject { generator.generate }

          it { is_expected.to be_a_kind_of(Array) }

          it 'generate plugins have options' do
            expect(subject.any?(&:options)).to be true
          end

          it 'have a DummyFormat' do
            expect(subject.first).to be_a_kind_of DummyFormat
          end

          it 'have only a format options' do
            expect(subject.first.options).to eq DUMMY_OPTIONS[:formats][:dummy_format]
          end
        end
      end
    end
  end
end
