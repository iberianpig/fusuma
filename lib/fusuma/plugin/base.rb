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

      # config parameter name and Type of the value of parameter
      # @return [Hash]
      def config_param_types
        raise NotImplementedError, "override #{self.class.name}##{__method__}"
      end

      # @return [Plugin::Base]
      def config_params(key = nil)
        params = Config.search(config_index) || {}

        return params unless key

        params.fetch(key, nil).tap do |val|
          next if val.nil?

          param_types = Array(config_param_types.fetch(key))

          next if param_types.any? { |klass| val.is_a?(klass) }

          MultiLogger.error('Please fix config.yml.')
          MultiLogger.error(":#{config_index.keys.map(&:symbol)
            .join(' => :')} => :#{key} should be #{param_types.join(' OR ')}.")
          exit 1
        end
      end

      def config_index
        Config::Index.new(self.class.name.gsub('Fusuma::', '').underscore.split('/'))
      end
    end
  end
end
