# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/config"

# spec for Config
module Fusuma
  RSpec.describe Config do
    let(:keymap) do
      {
        "swipe" => {
          3 => {
            "left" => {"command" => "alt+Left"},
            "right" => {"command" => "alt+Right"}
          },
          4 => {
            "left" => {"command" => "super+Left"},
            "right" => {"command" => "super+Right"}
          }
        },
        "pinch" => {
          "in" => {"command" => "ctrl+plus"},
          "out" => {"command" => "ctrl+minus"}
        }
      }
    end

    describe ".custom_path=" do
      before { Singleton.__init__(Config) }
      it "should reload keymap file" do
        keymap = Config.instance.keymap
        Config.custom_path = "./spec/fusuma/dummy_config.yml"
        custom_keymap = Config.instance.keymap
        expect(keymap).not_to eq custom_keymap
      end
    end

    describe "#reload" do
      before { Singleton.__init__(Config) }
      it "set Seacher" do
        old = Config.instance.searcher
        Config.instance.reload
        expect(Config.instance.searcher).not_to eq(old)
      end
    end

    describe "#validate" do
      context "with valid yaml" do
        before do
          string = <<~CONFIG
            swipe:
              3:
                left:
                  command: echo 'swipe left'

          CONFIG
          @config_file = Tempfile.open do |temp_file|
            temp_file.tap { |f| f.write(string) }
          end
        end

        it "should return Hash" do
          Config.instance.validate(@config_file.path)
        end
      end

      context "with invalid yaml" do
        before do
          string = <<~CONFIG
            this is not yaml
          CONFIG
          @config_file = Tempfile.open do |temp_file|
            temp_file.tap { |f| f.write(string) }
          end
        end

        it "raise InvalidFileError" do
          expect { Config.instance.validate(@config_file.path) }.to raise_error(Config::InvalidFileError)
        end

        context "invalid syntax" do

          before do
            string = <<~CONFIG
              - "aaaa"
              "bbbb" # invalid syntax
            CONFIG
            @config_file = Tempfile.open do |temp_file|
              temp_file.tap { |f| f.write(string) }
            end
          end

          it "raise InvalidFileError" do
            expect { Config.instance.validate(@config_file.path) }.to raise_error(Config::InvalidFileError)
          end
        end

        context "with duplicated key" do
          before do
            string = <<~CONFIG
              pinch:
                2:
                  in:
                    command: "xdotool keydown ctrl click 4 keyup ctrl" # threshold: 0.5, interval: 0.5
                2:
                  out:
                    command: "xdotool keydown ctrl click 5 keyup ctrl" # threshold: 0.5, interval: 0.5
            CONFIG
            @config_file = Tempfile.open do |temp_file|
              temp_file.tap { |f| f.write(string) }
            end
          end

          it "raise InvalidFileError" do
            expect { Config.instance.validate(@config_file.path) }.to raise_error(Config::InvalidFileError)
          end
        end
      end
    end
  end
end
