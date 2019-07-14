# frozen_string_literal: true

require_relative './manager.rb'
require_relative '../config.rb'

module Fusuma
  module Plugin
    # Create a Plugin Class with extending this class
    class Base
      # when inherited from subclass
      def self.inherited(subclass)
        subclass_path = caller_locations(1..1).first.path
        Manager.add(plugin_class: subclass, plugin_path: subclass_path)
      end

      # get inherited classes
      # @example
      #  [Vectors::Vector]
      # @return [Array]
      def self.plugins
        Manager.plugins[name]
      end

      # @return [Plugin::Base]
      def config_params
        Config.search(config_index) || {}
      end

      def config_index
        Config::Index.new(self.class.name.gsub('Fusuma::', '').underscore.split('/'))
      end
    end
  end
end
