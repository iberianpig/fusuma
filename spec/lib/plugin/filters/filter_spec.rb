require 'spec_helper'
require './lib/fusuma/plugin/filters/filter.rb'
require './lib/fusuma/plugin/formats/event_format.rb'

module Fusuma
  module Plugin
    module Filters
      DUMMY_OPTIONS = { filters: { dummy_filter: 'dummy' } }.freeze

      class DummyFilter < Filter
        DEFAULT_SOURCE = 'dummy_input'.freeze
      end

      RSpec.describe Filter do
        let(:options) { DUMMY_OPTIONS }
        let(:filter) { DummyFilter.new(options: options) }

        describe '#source' do
          subject { filter.source }

          it { is_expected.to be DummyFilter::DEFAULT_SOURCE }
        end

        describe '#filter' do
          subject { filter.filter(event) }
          let(:event) { Formats::Event.new(tag: 'dummy_input', record: 'dummy') }

          context 'when filter#keep? return false' do
            before do
              allow(filter).to receive(:keep?).and_return(false)
            end

            it { is_expected.to be nil }
          end

          context 'when filter#keep? return true' do
            before do
              allow(filter).to receive(:keep?).and_return(true)
            end

            it { is_expected.to be event }
          end
        end
      end

      RSpec.describe Generator do
        let(:options) { DUMMY_OPTIONS }
        let(:generator) { described_class.new(options: options) }

        before do
          allow(generator).to receive(:plugins) { [DummyFilter] }
        end

        describe '#generate' do
          subject { generator.generate }

          it { is_expected.to be_a_kind_of(Array) }

          it 'generate plugins have options' do
            expect(subject.any?(&:options)).to be true
          end

          it 'have a DummyFilter' do
            expect(subject.first).to be_a_kind_of DummyFilter
          end

          it 'have only a filter options' do
            expect(subject.first.options).to eq DUMMY_OPTIONS[:filters][:dummy_filter]
          end
        end
      end
    end
  end
end
