# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/base"
require "./lib/fusuma/plugin/manager"
require "./lib/fusuma/plugin/inputs/input"
require "./lib/fusuma/plugin/filters/filter"

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
        subject { Manager.plugins }

        it "returns a Hash of plugin classes" do
          expect(subject).to be_a(Hash)
        end

        it "contains registered plugins" do
          expect(subject[Base.name]).to include(Inputs::Input)
        end
      end

      describe ".load_paths" do
        subject { Manager.load_paths }

        it "returns an Array of plugin paths" do
          expect(subject).to be_an(Array)
        end

        it "contains paths of registered plugins" do
          expect(subject).to include(a_string_matching(%r{fusuma/plugin/inputs/input\.rb}))
        end
      end

      describe ".exist?" do
        let(:plugin_class) { Inputs::Input }
        let(:plugin_path) { Manager.load_paths.find { |p| p.include?("inputs/input.rb") } }

        context "when plugin path is already in load_paths" do
          it "returns false to allow multiple classes from same file" do
            # This allows subclasses defined in the same file to be registered
            expect(Manager.exist?(plugin_class: plugin_class, plugin_path: plugin_path)).to be false
          end
        end

        context "when plugin path is in load_paths (even with different class)" do
          it "returns false to allow multiple classes from same file" do
            # Even with a different class, returns false if path is already registered
            # This design allows multiple plugin classes from the same file
            expect(Manager.exist?(plugin_class: Filters::Filter, plugin_path: plugin_path)).to be false
          end
        end

        context "when plugin class is registered but path is different" do
          it "returns true if class is already in plugins" do
            expect(Manager.exist?(plugin_class: plugin_class, plugin_path: "/different/path.rb")).to be true
          end
        end

        context "when plugin class is registered (different path)" do
          it "returns true" do
            # Filters::Filter is registered, so it should return true
            expect(Manager.exist?(plugin_class: Filters::Filter, plugin_path: "/nonexistent/path.rb")).to be true
          end
        end

        context "when superclass has no registered plugins" do
          it "returns false" do
            # Create a mock class
            unknown_base = double("UnknownBase", name: "UnknownBase")
            stub_class = double("StubClass", superclass: unknown_base)

            expect(Manager.exist?(plugin_class: stub_class, plugin_path: "/nonexistent/path.rb")).to be false
          end
        end
      end

      describe ".add" do
        let(:test_plugin_path) { "/tmp/test_plugin_#{Time.now.to_i}_#{rand(10000)}.rb" }

        before do
          # Reset the already_required state for clean test
          Manager.instance_variable_set(:@already_required, {})
        end

        context "when plugin path is already in load_paths" do
          it "does not return false (allows multiple classes from same file)" do
            existing_path = Manager.load_paths.find { |p| p.include?("inputs/input.rb") }
            # Since path is already loaded, exist? returns false, so add continues
            # But since Input is already in plugins, it gets added again
            # This is the expected behavior for supporting multiple classes per file
            result = Manager.add(plugin_class: Inputs::Input, plugin_path: existing_path)
            expect(result).not_to be false
          end
        end

        context "when plugin class is already registered (different path)" do
          it "returns false" do
            result = Manager.add(plugin_class: Inputs::Input, plugin_path: test_plugin_path)
            expect(result).to be false
          end
        end

        context "when adding a new plugin" do
          let(:new_plugin_class) { nil }
          let(:added_path) { nil }

          after do
            # Cleanup: remove added test plugin from Manager
            Manager.plugins[Base.name]&.reject! { |p| p.is_a?(RSpec::Mocks::Double) }
            Manager.load_paths.reject! { |p| p.start_with?("/tmp/test_plugin_") }
          end

          it "registers the plugin class in plugins hash" do
            mock_plugin = double("NewPluginClass1", superclass: Base, name: "Fusuma::Plugin::TestPlugin1")
            manager_instance = instance_double(Manager)
            allow(Manager).to receive(:new).and_return(manager_instance)
            allow(manager_instance).to receive(:search_key).and_return("test/key/1")
            allow(manager_instance).to receive(:require_siblings_from_plugin_dir).and_return([])
            allow(manager_instance).to receive(:require_siblings_from_gems).and_return([])

            Manager.add(plugin_class: mock_plugin, plugin_path: test_plugin_path)

            expect(Manager.plugins[Base.name]).to include(mock_plugin)
          end

          it "adds path to load_paths" do
            mock_plugin = double("NewPluginClass2", superclass: Base, name: "Fusuma::Plugin::TestPlugin2")
            manager_instance = instance_double(Manager)
            allow(Manager).to receive(:new).and_return(manager_instance)
            allow(manager_instance).to receive(:search_key).and_return("test/key/2")
            allow(manager_instance).to receive(:require_siblings_from_plugin_dir).and_return([])
            allow(manager_instance).to receive(:require_siblings_from_gems).and_return([])

            path = "/tmp/test_plugin_path_#{rand(10000)}.rb"
            Manager.add(plugin_class: mock_plugin, plugin_path: path)

            expect(Manager.load_paths).to include(path)
          end

          it "calls require_siblings methods and returns result" do
            mock_plugin = double("NewPluginClass3", superclass: Base, name: "Fusuma::Plugin::TestPlugin3")
            manager_instance = instance_double(Manager)
            allow(Manager).to receive(:new).and_return(manager_instance)
            allow(manager_instance).to receive(:search_key).and_return("unique/key/3")
            allow(manager_instance).to receive(:require_siblings_from_plugin_dir).and_return(["/path/to/plugin1.rb"])
            allow(manager_instance).to receive(:require_siblings_from_gems).and_return(["/path/to/gem_plugin.rb"])

            path = "/tmp/test_plugin_unique_#{rand(10000)}.rb"
            result = Manager.add(plugin_class: mock_plugin, plugin_path: path)

            expect(result).to eq(["/path/to/gem_plugin.rb"])
          end
        end

        context "when search_key is already required" do
          after do
            # Cleanup
            Manager.plugins[Base.name]&.reject! { |p| p.is_a?(RSpec::Mocks::Double) }
            Manager.load_paths.reject! { |p| p.start_with?("/tmp/") }
          end

          it "returns nil without requiring again" do
            stub_class1 = double("TestPlugin1", superclass: Base, name: "Fusuma::Plugin::TestPlugin1")
            stub_class2 = double("TestPlugin2", superclass: Base, name: "Fusuma::Plugin::TestPlugin2")
            manager_instance = instance_double(Manager)
            allow(Manager).to receive(:new).and_return(manager_instance)
            allow(manager_instance).to receive(:search_key).and_return("already/required/key")
            allow(manager_instance).to receive(:require_siblings_from_plugin_dir).and_return([])
            allow(manager_instance).to receive(:require_siblings_from_gems).and_return([])

            # First call - should require
            first_path = "/tmp/first_#{rand(10000)}.rb"
            Manager.add(plugin_class: stub_class1, plugin_path: first_path)

            # Second call with same search_key - should skip requiring
            second_path = "/tmp/second_#{rand(10000)}.rb"
            result = Manager.add(plugin_class: stub_class2, plugin_path: second_path)

            expect(result).to be_nil
          end
        end
      end
    end
  end
end
