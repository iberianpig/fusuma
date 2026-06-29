# frozen_string_literal: true

require_relative "manager"
require_relative "../config"
require_relative "../custom_process"

module Fusuma
  module Plugin
    # Create a Plugin Class with extending this class
    class Base
      # Callback when a subclass inherits from this class.
      # Registers the subclass with the plugin manager.
      def self.inherited(subclass)
        super

        locations = Kernel.caller_locations(1..1)
        if locations.nil? || locations.empty?
          raise "Plugin class #{subclass.name} must be defined in a file."
        end

        subclass_path = locations.first&.path
        if subclass_path.nil?
          raise "Plugin class #{subclass.name} must have a valid file path."
        end

        Manager.add(plugin_class: subclass, plugin_path: subclass_path)
      end

      # get subclasses
      # @return [Array<Class>]
      def self.plugins
        Manager.plugins[name]
      end

      # @abstract override `#shutdown` to implement
      #: () -> void
      def shutdown
      end

      # config parameter name and Type of the value of parameter
      # @return [Hash]
      #: () -> Hash[Symbol, Class | Array[Class]]
      def config_param_types
        raise NotImplementedError, "override #{self.class.name}##{__method__}"
      end

      # @param key [Symbol]
      # @param base [Config::Index]
      # @return [Object]
      #: () -> Hash[untyped, untyped]
      #: (Symbol) -> untyped
      def config_params(key = nil)
        @config_params ||= {}
        if @config_params["#{config_index.cache_key},#{key}"]
          return @config_params["#{config_index.cache_key},#{key}"]
        end

        params = Config.instance.fetch_config_params(key, config_index)

        return params unless key

        value = params.fetch(key, nil)
        @config_params["#{config_index.cache_key},#{key}"] =
          if value.nil?
            # Not configured: skip type checking (and thus config_param_types,
            # which subclasses without params legitimately leave unimplemented).
            value
          else
            self.class.validate_param_type!(config_index, key, value, config_param_types.fetch(key))
          end
      end

      #: () -> Fusuma::Config::Index
      def config_index
        @config_index ||= self.class.config_index
      end

      # Class-level config lookup with type validation, usable BEFORE
      # instantiation (e.g. by Inputs::Input.enabled?, which must decide
      # whether to instantiate at all). Unlike the instance #config_params
      # it takes the accepted types explicitly, since #config_param_types
      # is defined per instance and not available before #initialize.
      #: (Symbol, untyped) -> untyped
      def self.config_param(key, types)
        index = config_index
        value = Config.instance.fetch_config_params(key, index).fetch(key, nil)
        validate_param_type!(index, key, value, types)
      end

      #: () -> Fusuma::Config::Index
      def self.config_index
        Config::Index.new(name.gsub("Fusuma::", "").underscore.split("/"))
      end

      # Validate that a config value matches one of the accepted types,
      # printing a helpful message and exiting on mismatch. A nil value
      # passes through (meaning "not configured"). Shared by the instance
      # #config_params and the class .config_param so the error format
      # stays identical.
      #: (Fusuma::Config::Index, Symbol, untyped, untyped) -> untyped
      def self.validate_param_type!(index, key, value, types)
        return value if value.nil?

        # NOTE: Type checking for config.yml
        param_types = Array(types)
        return value if param_types.any? { |klass| value.is_a?(klass) }

        MultiLogger.error("Please fix config.yml")
        MultiLogger.error("`#{index.keys.join(".")}.#{key}` should be #{param_types.join(" OR ")}.")
        exit 1
      end
    end
  end
end
