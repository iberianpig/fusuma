# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/events/records/record"

module Fusuma
  module Plugin
    module Events
      module Records
        RSpec.describe Record do
          before {
            allow(Record).to receive(:inherited) # disable autoload
            stub_const("DummyRecord", Class.new(Record) do
              def type
                :dummy
              end
            end)
          }
          let(:record) { described_class.new }

          describe "#type" do
            it { expect { record.type }.to raise_error(NotImplementedError) }

            context "override #type" do
              let(:record) { DummyRecord.new }
              it { expect { record.type }.not_to raise_error(NotImplementedError) }
              it { expect(record.type).to eq :dummy }
            end
          end
        end
      end
    end
  end
end
