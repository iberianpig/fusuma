# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/base"
require "./lib/fusuma/plugin/manager"
require "./lib/fusuma/plugin/inputs/input"

module Fusuma
  module Plugin
    RSpec.describe Manager do
      let(:manager) { Manager.new(Base) }
      describe "#require_siblings_from_plugin_dir" do
        subject { manager.require_siblings_from_plugin_dir }
        before { allow(manager).to receive(:fusuma_default_plugin_paths) { ["./path/to/dummy/plugin"] } }
        it {
          expect_any_instance_of(Kernel).to receive(:require).once
          subject
        }
      end

      describe "#require_siblings_from_gems" do
        subject { manager.require_siblings_from_gems }
        before { allow(manager).to receive(:fusuma_external_plugin_paths) { ["./path/to/dummy/plugin"] } }
        it {
          expect_any_instance_of(Kernel).to receive(:require).once
          subject
        }
      end

      describe "#fusuma_default_pugin_paths" do
        context "inputs" do
          subject { Manager.new(Inputs::Input).fusuma_default_plugin_paths }
          it {
            is_expected.to match [
              %r{fusuma/plugin/inputs/input.rb},
              %r{fusuma/plugin/inputs/libinput_command_input.rb},
              %r{fusuma/plugin/inputs/timer_input.rb}
            ]
          }
        end
      end

      describe "#fusuma_external_plugin_paths" do
      end

      describe ".plugins" do
        subject { Manger.plugins }
        pending
      end

      describe ".add" do
        it "requires and loads siblings hierarchy from fusuma"
        it "requires and loads siblings hierarchy from fusuma-plugin"
        it "does not register plugin already added"
        it "does not require plugin already tried"
      end
    end
  end
end
