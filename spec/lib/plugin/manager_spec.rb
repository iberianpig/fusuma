# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/base'
require './lib/fusuma/plugin/manager'
require './lib/fusuma/plugin/inputs/input'

module Fusuma
  module Plugin
    RSpec.describe Manager do
      let(:manager) { Manager.new(Base) }
      describe '#require_siblings_from_plugin_dir' do
        subject { manager.require_siblings_from_plugin_dir }
        before { allow(manager).to receive(:fusuma_default_plugin_paths) { ['./path/to/dummy/plugin'] } }
        it {
          expect_any_instance_of(Kernel).to receive(:require).once
          subject
        }
      end

      describe '#require_siblings_from_gems' do
        subject { manager.require_siblings_from_gems }
        before { allow(manager).to receive(:fusuma_external_plugin_paths) { ['./path/to/dummy/plugin'] } }
        it {
          expect_any_instance_of(Kernel).to receive(:require).once
          subject
        }
      end

      describe '#fusuma_default_pugin_paths' do
        it {
          expect(Manager.new(Inputs::Input).fusuma_default_plugin_paths).to match [
            %r{fusuma/plugin/inputs/input.rb},
            %r{fusuma/plugin/inputs/libinput_command_input.rb},
            %r{fusuma/plugin/inputs/timer_input.rb}
          ]
        }
      end

      describe '.plugins' do
        subject { Manger.plugins }
        pending
      end
    end
  end
end
