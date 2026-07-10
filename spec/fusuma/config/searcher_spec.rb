# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/config"
require "./lib/fusuma/config/searcher"

# spec for Config
module Fusuma
  RSpec.describe Config::Searcher do
    let(:config_yml) do
      <<~CONFIG
        swipe:
          3:
            left:
              command: 'alt+Left'
            right:
              command: 'alt+Right'
          4:
            left:
              command: 'super+Left'
            right:
              command: 'super+Right'
        pinch:
          in:
            command: 'ctrl+plus'
          out:
            command: 'ctrl+minus'
      CONFIG
    end

    around do |example|
      ConfigHelper.load_config_yml = config_yml

      example.run

      ConfigHelper.clear_config_yml
    end

    describe ".search" do
      let(:searcher) { Config::Searcher.new }
      let(:location) { Config.instance.keymap[0] }

      subject { searcher.search(index, location: location) }

      context "with correct key order" do
        let(:index) { Config::Index.new %w[pinch in command] }
        it { is_expected.to eq "ctrl+plus" }
      end

      context "with incorrect key order" do
        let(:index) { Config::Index.new %w[in pinch 2 command] }
        it { is_expected.to be_nil }
      end

      # nested recursive calls reused mutated index.keys
      context "index immutability" do
        let(:index) { Config::Index.new %w[pinch in command] }

        it "does not mutate the original index.keys after search" do
          original_keys_count = index.keys.size
          subject
          expect(index.keys.size).to eq(original_keys_count)
        end

        it "returns consistent results when searching with the same index multiple times" do
          expect(subject).to eq("ctrl+plus")
          expect(subject).to eq("ctrl+plus")
          expect(subject).to eq("ctrl+plus")
        end
      end

      context "with skippable keys" do
        context "when skippable key is in the middle" do
          let(:index) do
            Config::Index.new [
              Config::Index::Key.new("pinch"),
              Config::Index::Key.new(2, skippable: true),
              Config::Index::Key.new("out"),
              Config::Index::Key.new("command")
            ]
          end

          it { is_expected.to eq("ctrl+minus") }
        end

        context "when skippable keys are at the beginning and middle" do
          let(:index) do
            Config::Index.new [
              Config::Index::Key.new(:hoge, skippable: true),
              Config::Index::Key.new(:fuga, skippable: true),
              Config::Index::Key.new("pinch"),
              Config::Index::Key.new("in"),
              Config::Index::Key.new(:piyo, skippable: true),
              Config::Index::Key.new("command")
            ]
          end

          it { is_expected.to eq("ctrl+plus") }
        end

        context "with gesture lifecycle (begin/update/end)" do
          let(:config_yml) do
            <<~CONFIG
              swipe:
                3:
                  begin:
                    command: 'echo begin'
                  update:
                    command: 'echo update'
                  end:
                    command: 'echo end'
                    keypress:
                      LEFTCTRL:
                        command: 'echo end+ctrl'
            CONFIG
          end

          context "without keypress modifier" do
            let(:index) do
              Config::Index.new [
                Config::Index::Key.new(:swipe),
                Config::Index::Key.new(3),
                Config::Index::Key.new("left", skippable: true),
                Config::Index::Key.new("end"),
                Config::Index::Key.new("command")
              ]
            end

            it { is_expected.to eq("echo end") }
          end

          context "with keypress modifier" do
            context "when key exists in config" do
              let(:index) do
                Config::Index.new [
                  Config::Index::Key.new(:swipe),
                  Config::Index::Key.new(3),
                  Config::Index::Key.new("left", skippable: true),
                  Config::Index::Key.new("end"),
                  Config::Index::Key.new("keypress", skippable: true),
                  Config::Index::Key.new("LEFTCTRL", skippable: true),
                  Config::Index::Key.new("command")
                ]
              end

              it { is_expected.to eq("echo end+ctrl") }
            end

            context "when key does not exist in config (fallback)" do
              let(:index) do
                Config::Index.new [
                  Config::Index::Key.new(:swipe),
                  Config::Index::Key.new(3),
                  Config::Index::Key.new("up", skippable: true),
                  Config::Index::Key.new("end"),
                  Config::Index::Key.new("keypress", skippable: true),
                  Config::Index::Key.new("LEFTSHIFT", skippable: true),
                  Config::Index::Key.new("command")
                ]
              end

              it { is_expected.to eq("echo end") }
            end
          end
        end
      end
    end

    describe ".find_context" do
      let(:config_yml) do
        <<~CONFIG
          ---
          context: { plugin_defaults: "libinput_command_input" }
          plugin:
            inputs:
              libinput_command_input:
          ---
          context: { plugin_defaults: "sendkey_executor" }
          plugin:
            executors:
              sendkey_executor:
                device_name: keyboard|Keyboard|KEYBOARD
        CONFIG
      end

      it "should find matched context and matched value" do
        request_context = {plugin_defaults: "sendkey_executor"}
        fallbacks = [:no_context, :plugin_default_context]

        device_name = nil
        matched = Config::Searcher.find_context(request_context, fallbacks) do
          # search device_name from sendkey_executor context
          device_name = Config.search(Config::Index.new(%w[plugin executors sendkey_executor device_name]))
        end

        expect(matched).to eq request_context
        expect(device_name).to eq "keyboard|Keyboard|KEYBOARD"
      end

      context "with OR condition (array value)" do
        let(:config_yml) do
          <<~CONFIG
            ---
            context:
              application:
                - Chrome
                - Firefox
            swipe:
              3:
                left:
                  command: 'browser-back'
          CONFIG
        end

        it "matches when request value is in the array" do
          request_context = {application: "Chrome"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[swipe 3 left command]))
          end
          expect(matched).to eq({application: ["Chrome", "Firefox"]})
        end

        it "matches when request value is another element in the array" do
          request_context = {application: "Firefox"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[swipe 3 left command]))
          end
          expect(matched).to eq({application: ["Chrome", "Firefox"]})
        end

        it "returns nil when request value is not in the array and no default exists" do
          request_context = {application: "Safari"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[swipe 3 left command]))
          end
          expect(matched).to be_nil
        end
      end

      context "with AND + OR condition" do
        let(:config_yml) do
          <<~CONFIG
            ---
            context:
              thumbsense: true
              application:
                - Chrome
                - Firefox
            remap:
              H: 'alt+Left'
          CONFIG
        end

        it "matches when both AND and OR conditions are satisfied" do
          request_context = {thumbsense: true, application: "Chrome"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[remap H]))
          end
          expect(matched).to eq({thumbsense: true, application: ["Chrome", "Firefox"]})
        end

        it "returns nil when OR is satisfied but AND is not" do
          request_context = {thumbsense: false, application: "Chrome"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[remap H]))
          end
          expect(matched).to be_nil
        end

        it "returns nil when AND is satisfied but OR is not" do
          request_context = {thumbsense: true, application: "Safari"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[remap H]))
          end
          expect(matched).to be_nil
        end
      end

      context "with same application in multiple context blocks (OR and single)" do
        let(:config_yml) do
          <<~CONFIG
            ---
            context:
              application:
                - Google-chrome
                - Microsoft-edge-dev
            remap:
              LEFTCTRL+Q: 'LEFTCTRL+W'
            ---
            context:
              application: Google-chrome
            swipe:
              3:
                left:
                  sendkey: "LEFTALT+RIGHT"
          CONFIG
        end

        it "finds remap config for Google-chrome via OR condition" do
          request_context = {application: "Google-chrome"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[remap LEFTCTRL+Q]))
          end
          expect(matched).to eq({application: ["Google-chrome", "Microsoft-edge-dev"]})
        end

        it "finds swipe config for Google-chrome via single value condition" do
          request_context = {application: "Google-chrome"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[swipe 3 left sendkey]))
          end
          expect(matched).to eq({application: "Google-chrome"})
        end

        it "finds remap config for Microsoft-edge-dev via OR condition" do
          request_context = {application: "Microsoft-edge-dev"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[remap LEFTCTRL+Q]))
          end
          expect(matched).to eq({application: ["Google-chrome", "Microsoft-edge-dev"]})
        end

        it "does not find swipe config for Microsoft-edge-dev (not in single value context)" do
          request_context = {application: "Microsoft-edge-dev"}
          matched = Config::Searcher.find_context(request_context) do
            Config.search(Config::Index.new(%w[swipe 3 left sendkey]))
          end
          expect(matched).to be_nil
        end

        # Test for with_context (used by fusuma-plugin-remap)
        it "finds remap config via with_context for Google-chrome (OR condition)" do
          result = Config::Searcher.with_context({application: "Google-chrome"}) do
            Config.search(Config::Index.new(%w[remap LEFTCTRL+Q]))
          end
          expect(result).to eq("LEFTCTRL+W")
        end

        it "finds remap config via with_context for Microsoft-edge-dev (OR condition)" do
          result = Config::Searcher.with_context({application: "Microsoft-edge-dev"}) do
            Config.search(Config::Index.new(%w[remap LEFTCTRL+Q]))
          end
          expect(result).to eq("LEFTCTRL+W")
        end

        it "does not find remap config via with_context for Firefox (not in OR array)" do
          result = Config::Searcher.with_context({application: "Firefox"}) do
            Config.search(Config::Index.new(%w[remap LEFTCTRL+Q]))
          end
          expect(result).to be_nil
        end
      end
    end

    describe "#search_with_context" do
      let(:searcher) { Config::Searcher.new }

      context "with no-context and context blocks" do
        let(:config_yml) do
          <<~CONFIG
            ---
            swipe:
              3:
                left:
                  command: 'default-back'
            ---
            context:
              application:
                - Google-chrome
                - Firefox
            swipe:
              3:
                left:
                  command: 'browser-back'
          CONFIG
        end

        let(:location) { Config.instance.keymap }
        let(:index) { Config::Index.new(%w[swipe 3 left command]) }

        context "when context is nil" do
          it "searches in no-context blocks only" do
            result = searcher.search_with_context(index, location: location, context: nil)
            expect(result).to eq("default-back")
          end
        end

        context "when context is empty hash" do
          it "searches in no-context blocks only" do
            result = searcher.search_with_context(index, location: location, context: {})
            expect(result).to eq("default-back")
          end
        end

        context "when context matches OR condition" do
          it "searches in context blocks matching the condition" do
            result = searcher.search_with_context(index, location: location, context: {application: "Google-chrome"})
            expect(result).to eq("browser-back")
          end

          it "matches another value in OR array" do
            result = searcher.search_with_context(index, location: location, context: {application: "Firefox"})
            expect(result).to eq("browser-back")
          end
        end

        context "when context does not match any block" do
          it "returns nil" do
            result = searcher.search_with_context(index, location: location, context: {application: "Safari"})
            expect(result).to be_nil
          end
        end
      end

      context "with no-context block only" do
        let(:config_yml) do
          <<~CONFIG
            swipe:
              3:
                left:
                  command: 'default-back'
          CONFIG
        end

        let(:location) { Config.instance.keymap }
        let(:index) { Config::Index.new(%w[swipe 3 left command]) }

        it "returns nil when searching with specific context" do
          result = searcher.search_with_context(index, location: location, context: {application: "Chrome"})
          expect(result).to be_nil
        end
      end

      context "skipping no-context blocks when context is specified" do
        let(:config_yml) do
          <<~CONFIG
            ---
            remap:
              H: 'default-h'
            ---
            context:
              thumbsense: true
            remap:
              H: 'thumbsense-h'
          CONFIG
        end

        let(:location) { Config.instance.keymap }
        let(:index) { Config::Index.new(%w[remap H]) }

        it "skips no-context block and finds context block" do
          result = searcher.search_with_context(index, location: location, context: {thumbsense: true})
          expect(result).to eq("thumbsense-h")
        end

        it "finds no-context block when context is nil" do
          result = searcher.search_with_context(index, location: location, context: nil)
          expect(result).to eq("default-h")
        end

        it "returns nil when context does not match" do
          result = searcher.search_with_context(index, location: location, context: {thumbsense: false})
          expect(result).to be_nil
        end
      end
    end

    describe "private_method: :cache" do
      it "should cache command" do
        key = %w[event_type finger direction command].join(",")
        value = "shourtcut string"
        searcher = Config::Searcher.new
        searcher.send(:cache, key) { value }
        expect(searcher.send(:cache, key)).to eq value
      end
    end
  end
end
