# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/events/records/record"
require "./lib/fusuma/plugin/events/records/context_record"

module Fusuma
  module Plugin
    module Events
      module Records
        RSpec.describe ContextRecord do
          let(:record) { described_class.new(name: "application", value: "Firefox") }

          describe "#type" do
            subject { record.type }
            it { is_expected.to eq :context }
          end

          describe "#name" do
            subject { record.name }
            it "is converted to a Symbol" do
              is_expected.to eq :application
            end
          end

          describe "#value" do
            subject { record.value }
            it { is_expected.to eq "Firefox" }
          end
        end
      end
    end
  end
end
