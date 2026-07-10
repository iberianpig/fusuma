# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/config/yaml_duplication_checker"

module Fusuma
  RSpec.describe Config::YAMLDuplicationChecker do
    describe ".check" do
      def duplicates_in(yaml_string)
        [].tap do |duplicates|
          described_class.check(yaml_string, "fusuma_config.yml") do |exist, duplicated|
            duplicates << [exist, duplicated]
          end
        end
      end

      context "with duplicated top-level keys" do
        let(:yaml_string) do
          <<~YAML
            swipe:
              3:
                left:
                  command: "command1"
            swipe:
              4:
                left:
                  command: "command2"
          YAML
        end

        it "calls the block once with the existing and duplicated key nodes" do
          duplicates = duplicates_in(yaml_string)

          expect(duplicates.size).to eq(1)

          exist, duplicated = duplicates.first
          expect(exist).to be_a(Psych::Nodes::Scalar)
          expect(duplicated).to be_a(Psych::Nodes::Scalar)
          expect(exist.value).to eq("swipe")
          expect(duplicated.value).to eq("swipe")
          expect(exist.start_line).to be < duplicated.start_line
        end
      end

      context "with duplicated keys in a nested mapping" do
        let(:yaml_string) do
          <<~YAML
            swipe:
              3:
                left:
                  command: "command1"
                left:
                  command: "command2"
          YAML
        end

        it "detects the duplicated nested keys" do
          duplicates = duplicates_in(yaml_string)

          expect(duplicates.size).to eq(1)

          exist, duplicated = duplicates.first
          expect(exist.value).to eq("left")
          expect(duplicated.value).to eq("left")
          expect(exist.start_line).to be < duplicated.start_line
        end
      end

      context "with same-named keys at different levels" do
        let(:yaml_string) do
          <<~YAML
            swipe:
              3:
                left:
                  command: "command1"
              4:
                left:
                  command: "command2"
          YAML
        end

        it "does not report them as duplicated" do
          expect(duplicates_in(yaml_string)).to be_empty
        end
      end

      context "without duplicated keys" do
        let(:yaml_string) do
          <<~YAML
            swipe:
              3:
                left:
                  command: "command1"
                right:
                  command: "command2"
          YAML
        end

        it "does not call the block" do
          expect(duplicates_in(yaml_string)).to be_empty
        end
      end

      context "with an empty string" do
        let(:yaml_string) { "" }

        it "does not call the block" do
          expect(duplicates_in(yaml_string)).to be_empty
        end
      end
    end
  end
end
