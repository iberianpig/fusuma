# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/config"
require "./lib/fusuma/plugin/filters/filter"
require "./lib/fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Filters
      class DummyFilter < Filter
        DEFAULT_SOURCE = "dummy_input"

        def config_param_types
          {
            source: String,
            dummy: String
          }
        end
      end

      RSpec.describe DummyFilter do
        let(:filter) { DummyFilter.new }

        describe "#source" do
          subject { filter.source }

          it { is_expected.to eq DummyFilter::DEFAULT_SOURCE }

          context "with config" do
            around do |example|
              @custom_source = "custom_input"

              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                 filters:
                   dummy_filter:
                     source: #{@custom_source}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { is_expected.to eq @custom_source }
          end
        end

        describe "#filter" do
          subject { filter.filter(event) }
          let(:event) { Events::Event.new(tag: "dummy_input", record: "dummy") }

          context "when filter#keep? return false" do
            before do
              allow(filter).to receive(:keep?).and_return(false)
            end

            it { is_expected.to be nil }
          end

          context "when filter#keep? return true" do
            before do
              allow(filter).to receive(:keep?).and_return(true)
            end

            it { is_expected.to be event }
          end
        end

        describe "#config_params" do
          around do |example|
            ConfigHelper.load_config_yml = <<~CONFIG
              plugin:
               filters:
                 dummy_filter:
                   dummy: dummy
            CONFIG

            example.run

            Config.custom_path = nil
          end

          subject { filter.config_params(:dummy) }
          it { is_expected.to eq("dummy") }
        end
      end
    end
  end
end
