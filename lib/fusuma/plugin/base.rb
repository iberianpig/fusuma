# frozen_string_literal: true

require_relative "manager"
require_relative "../config"
require_relative "../custom_process"

module Fusuma
  module Plugin
    # Create a Plugin Class with extending this class
    class Base
      # when inherited from subclass
      def self.inherited(subclass)
        super

        locations = Kernel.caller_locations(1..1)
        if locations.nil? || locations.empty?
          raise "Plugin class #{subclass.name} must be defined in a file."
        end

        subclass_path = locations.first.path
        Manager.add(plugin_class: subclass, plugin_path: subclass_path)
      end

      # get subclasses
      # @return [Array<Class>]
      def self.plugins
        Manager.plugins[name]
      end

      # @abstract override `#shutdown` to implement
      #: () -> nil
      def shutdown
      end

      # config parameter name and Type of the value of parameter
      # @return [Hash]
      #: () -> Hash[Symbol, Array[Class] | Class]
      def config_param_types
        raise NotImplementedError, "override #{self.class.name}##{__method__}"
      end

      # @param key [Symbol]
      # @param base [Config::Index]
      # @return [Object]
      #: (?Symbol?) -> (String | Hash[untyped, untyped] | Float | bool)?
      def config_params(key = nil)
        @config_params ||= {}
        if @config_params["#{config_index.cache_key},#{key}"]
          return @config_params["#{config_index.cache_key},#{key}"]
        end

        params = Config.instance.fetch_config_params(key, config_index)

        return params unless key

        @config_params["#{config_index.cache_key},#{key}"] =
          params.fetch(key, nil).tap do |val|
            next if val.nil?

            # NOTE: Type checking for config.yml
            param_types = Array(config_param_types.fetch(key))

            next if param_types.any? { |klass| val.is_a?(klass) }

            MultiLogger.error("Please fix config.yml")
            MultiLogger.error("`#{config_index.keys.join(".")}.#{key}` should be #{param_types.join(" OR ")}.")
            exit 1
          end
      end

      #: () -> Fusuma::Config::Index
      def config_index
        @config_index ||= Config::Index.new(self.class.name.gsub("Fusuma::", "").underscore.split("/"))
      end
    end
  end
end
