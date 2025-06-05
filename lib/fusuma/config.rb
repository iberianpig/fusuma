# frozen_string_literal: true

require_relative "multi_logger"
require_relative "config/index"
require_relative "config/searcher"
require_relative "config/yaml_duplication_checker"
require_relative "plugin/manager"
require_relative "hash_support"
require "singleton"
require "yaml"

# module as namespace
module Fusuma
  # read keymap from yaml file
  class Config
    class NotFoundError < StandardError; end

    class InvalidFileError < StandardError; end

    include Singleton

    class << self
      #: (Fusuma::Config::Index) -> (String | Hash[untyped, untyped] | Integer | Float)?
      def search(index)
        instance.search(index)
      end

      def find_execute_key(index)
        instance.find_execute_key(index)
      end

      #: (String?) -> Fusuma::Config
      def custom_path=(new_path)
        instance.custom_path = new_path
      end
    end

    attr_reader :custom_path, :searcher

    #: () -> void
    def initialize
      @searcher = Searcher.new
      @custom_path = nil
      @keymap = nil
    end

    #: (String?) -> Fusuma::Config
    def custom_path=(new_path)
      @custom_path = new_path
      reload
    end

    #: () -> Array[untyped]?
    def keymap
      # FIXME: @keymap is not initialized when called from outside Fusuma::Runner like fusuma-senkey
      @keymap || reload.keymap
    end

    #: () -> Fusuma::Config
    def reload
      plugin_defaults = plugin_defaults_paths.map do |default_yml|
        {
          context: {plugin_defaults: default_yml.split("/").last.delete_suffix(".yml")},
          **validate(default_yml)[0]
        }
      end

      config_path = find_config_filepath
      @keymap = validate(config_path) | plugin_defaults
      MultiLogger.info "reload config: #{config_path}"

      # reset searcher cache
      @searcher = Searcher.new
      @cache_execute_keys = nil

      self
    rescue InvalidFileError => e
      MultiLogger.error e.message
      exit 1
    end

    # @param key [Symbol]
    # @param base [Config::Index]
    # @return [Hash]
    #: (Symbol?, Fusuma::Config::Index) -> (String | Hash[untyped, untyped] | Float | Integer | bool)?
    def fetch_config_params(key, base)
      request_context = {plugin_defaults: base.keys.last.symbol.to_s}
      fallbacks = [:no_context, :plugin_default_context]
      Config::Searcher.find_context(request_context, fallbacks) do
        ret = Config.search(base)
        if ret&.key?(key)
          return ret
        end
      end
      {}
    end

    # @return [Hash] If check passes
    # @raise [InvalidFileError] If check does not pass
    #: (String) -> Array[Hash[Symbol, untyped]]
    def validate(path)
      duplicates = []
      YAMLDuplicationChecker.check(File.read(path), path) do |ignored, duplicate| # steep:ignore UnexpectedBlockGiven
        MultiLogger.error "#{path}: #{ignored.value} is duplicated"
        duplicates << duplicate.value
      end
      raise InvalidFileError, "Detect duplicate keys #{duplicates}" unless duplicates.empty?

      yamls = YAML.load_stream(File.read(path)).compact # steep:ignore NoMethod
      yamls.map do |yaml|
        raise InvalidFileError, "Invalid config.yml: #{path}" unless yaml.is_a? Hash

        yaml.deep_symbolize_keys
      end
    rescue Psych::SyntaxError => e
      raise InvalidFileError, "Invalid syntax: #{path} #{e.message}"
    end

    # @param index [Index]
    #: (Fusuma::Config::Index) -> (String | Hash[untyped, untyped] | Integer | Float)?
    def search(index)
      return nil if index.nil? || index.keys.empty?
      @searcher.search_with_cache(index, location: keymap)
    end

    # @param index [Config::Index]
    # @return Symbol
    def find_execute_key(index)
      @execute_keys ||= Plugin::Executors::Executor.plugins.map do |executor|
        executor.new.execute_keys
      end.flatten

      @cache_execute_keys ||= {} #: Hash[String, untyped]

      cache_key = [index.cache_key, Searcher.context].join

      return @cache_execute_keys[cache_key] if @cache_execute_keys.has_key?(cache_key)

      @cache_execute_keys[cache_key] =
        @execute_keys.find do |execute_key|
          new_index = Config::Index.new(index.keys | [execute_key])
          search(new_index)
        end
    end

    private

    #: () -> String
    def find_config_filepath
      filename = "fusuma/config.yml"
      if custom_path
        return expand_custom_path if File.exist?(expand_custom_path)

        raise NotFoundError, "#{expand_custom_path} is NOT FOUND"
      elsif File.exist?(expand_config_path(filename))
        expand_config_path(filename)
      else
        MultiLogger.warn "config file: #{expand_config_path(filename)} is NOT FOUND"
        expand_default_path(filename)
      end
    end

    #: () -> String
    def expand_custom_path
      File.expand_path(custom_path)
    end

    #: (String) -> String
    def expand_config_path(filename)
      File.expand_path "~/.config/#{filename}"
    end

    def expand_default_path(filename)
      File.expand_path "../../#{filename}", __FILE__
    end

    #: () -> Array[untyped]
    def plugin_defaults_paths
      Plugin::Manager.load_paths.map do |plugin_path|
        yml = plugin_path.gsub(/\.rb$/, ".yml")
        yml if File.exist?(yml)
      end.compact
    end
  end
end
