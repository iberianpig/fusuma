# frozen_string_literal: true

require_relative './manager'
require_relative '../config'
require_relative '../custom_process'

module Fusuma
  module Plugin
    # Create a Plugin Class with extending this class
    class Base
      include CustomProcess
      # when inherited from subclass
      def self.inherited(subclass)
        super
        subclass_path = caller_locations(1..1).first.path
        Manager.add(plugin_class: subclass, plugin_path: subclass_path)
      end

      # get subclasses
      # @return [Array<Class>]
      def self.plugins
        Manager.plugins[name]
      end

      # config parameter name and Type of the value of parameter
      # @return [Hash]
      def config_param_types
        raise NotImplementedError, "override #{self.class.name}##{__method__}"
      end

      # @return [Object]
      def config_params(key = nil, base: config_index)
        params = Config.search(base) || {}

        return params unless key

        params.fetch(key, nil).tap do |val|
          next if val.nil?

          # NOTE: Type checking for config.yml
          param_types = Array(config_param_types.fetch(key))

          next if param_types.any? { |klass| val.is_a?(klass) }

          MultiLogger.error('Please fix config.yml.')
          MultiLogger.error(":#{base.keys.map(&:symbol)
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
