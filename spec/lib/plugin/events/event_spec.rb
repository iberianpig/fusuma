# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/events/event.rb'

module Fusuma
  module Plugin
    module Events
      RSpec.describe Event do
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
