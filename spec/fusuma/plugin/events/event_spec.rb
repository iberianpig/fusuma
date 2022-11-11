# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Events
      RSpec.describe Event do
        let(:event) { Event.new(**args) }
        let(:args) { {tag: "text", record: "dummy_text"} }

        before {
          allow(Records::Record).to receive(:inherited) # disable autoload
          stub_const("DummyRecord", Class.new(Records::Record))
        }

        describe "#record" do
          context "with text" do
            it { expect(event.record).to be_a Records::Record }
          end

          context "with Record" do
            let(:args) { {tag: "dummy_record", record: DummyRecord.new} }

            it { expect(event.record).to be_a Records::Record }
          end
        end
      end
    end
  end
end
