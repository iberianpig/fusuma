# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/events/records/record"
require "./lib/fusuma/plugin/events/records/index_record"
require "./lib/fusuma/plugin/executors/command_executor"
require "./lib/fusuma/config"

module Fusuma
  module Plugin
    module Events
      module Records
        RSpec.describe IndexRecord do
          let(:index) { Config::Index.new(["swipe", 3, "left"]) }
          let(:record) { described_class.new(index: index) }

          describe "#type" do
            subject { record.type }
            it { is_expected.to eq :index }
          end

          describe "#mergeable?" do
            subject { record.mergeable? }

            context "when position is :body (default)" do
              it { is_expected.to be true }
            end

            context "when position is :surfix" do
              let(:record) { described_class.new(index: index, position: :surfix) }
              it { is_expected.to be false }
            end
          end

          describe "#trigger_priority" do
            subject { record.trigger_priority }

            context "when trigger is :oneshot (default)" do
              it { is_expected.to eq 10 }
            end

            context "when trigger is :repeat" do
              let(:record) { described_class.new(index: index, trigger: :repeat) }
              it { is_expected.to eq 100 }
            end

            context "when trigger is unknown" do
              let(:record) { described_class.new(index: index, trigger: :dummy) }
              it { is_expected.to eq 1000 }
            end
          end

          describe "#to_s" do
            subject { record.to_s }
            it { is_expected.to eq "#{index}, body, oneshot, {}" }
          end

          describe "#merge" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                swipe:
                  3:
                    left:
                      command: "echo 'swipe left'"
                      keypress:
                        LEFTCTRL:
                          command: "echo 'LEFTCTRL + swipe left'"
              CONFIG

              example.run

              Config.custom_path = nil
            end

            context "with no records" do
              context "when the index has an executable command on config" do
                it "returns self" do
                  expect(record.merge(records: [])).to eq record
                end
              end

              context "when the index does not exist on config" do
                let(:index) { Config::Index.new(["swipe", 4, "left"]) }

                it "returns nil" do
                  expect(record.merge(records: [])).to be nil
                end
              end
            end

            context "with a surfix record" do
              let(:surfix_record) do
                described_class.new(
                  index: Config::Index.new(%w[keypress LEFTCTRL]),
                  position: :surfix
                )
              end

              it "returns self with an index merged with the surfix record" do
                merged = record.merge(records: [surfix_record])
                expect(merged).to eq record
                expect(merged.index.keys.map(&:symbol)).to eq [:swipe, 3, :left, :keypress, :LEFTCTRL]
              end
            end

            context "when the record itself is not :body position" do
              let(:record) { described_class.new(index: index, position: :surfix) }

              it "raises an error" do
                expect { record.merge(records: []) }.to raise_error(/position is NOT body/)
              end
            end

            context "with a :prefix position record" do
              let(:prefix_record) do
                described_class.new(index: Config::Index.new(["keypress"]), position: :prefix)
              end

              it "raises an error" do
                expect { record.merge(records: [prefix_record]) }.to raise_error(/invalid index position/)
              end
            end
          end
        end
      end
    end
  end
end
