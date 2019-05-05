require 'spec_helper'
require './lib/fusuma/plugin/formats/event_format.rb'

module Fusuma
  module Plugin
    module Formats
      RSpec.describe Format do
        let(:event) { Event.new(args) }
        let(:args) { { tag: 'text', record: 'dummy_text' } }

        class DummyRecord < Records::Record
        end

        describe '#record' do
          context 'with text' do
            it { expect(event.record).to be_a Records::Record }
          end

          context 'with Record' do
            let(:args) { { tag: 'dummy_record', record: DummyRecord.new } }

            it { expect(event.record).to be_a Records::Record }
          end
        end

        describe '#type' do
          subject { event.type }
          it { is_expected.to eq 'event' }
        end
      end
    end
  end
end
