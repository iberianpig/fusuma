# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/base'
require './lib/fusuma/plugin/manager'

module Fusuma
  module Plugin
    RSpec.describe Manager do
      describe '#require_siblings_from_plugin_dir' do
        Manager.new(Base).require_siblings_from_plugin_dir
        subject { Manager.new(Base).require_siblings_from_plugin_dir }
        it { expect { subject }.not_to raise_error(LoadError) }
      end

      describe '#require_siblings_from_gem' do
        subject { Manager.new(Inputs::Input).require_siblings_from_gem }
        it { expect { subject }.not_to raise_error(LoadError) }
      end

      describe '.plugins' do
        subject { Manger.plugins }
        pending
      end
    end
  end
end
