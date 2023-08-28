# frozen_string_literal: true

require_relative "./multi_logger"
require_relative "./config/index"
require_relative "./config/searcher"
require_relative "./config/yaml_duplication_checker"
require_relative "./hash_support"
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
      def search(index)
        instance.search(index)
      end

      def find_execute_key(index)
        instance.find_execute_key(index)
      end

      def custom_path=(new_path)
        instance.custom_path = new_path
      end
    end

    attr_reader :keymap, :custom_path, :searcher

    def initialize
      @searcher = Searcher.new
      @custom_path = nil
      @keymap = nil
    end

    def custom_path=(new_path)
      @custom_path = new_path
      reload
    end

    def reload
      plugin_defaults = {
        context: :plugin_defaults,
        plugin: {}
      }

      plugin_defaults_paths.each do |default_yml|
        plugin_defaults.deep_merge!(validate(default_yml)[0])
      end

      find_config_filepath.tap do |path|
        MultiLogger.info "reload config: #{path}"

        @keymap = validate(path).tap do |yamls|
          yamls << plugin_defaults
        end
      end

      # reset searcher cache
      @searcher = Searcher.new

      self
    rescue InvalidFileError => e
      MultiLogger.error e.message
      exit 1
    end

    # @param key [Symbol]
    # @param base [Config::Index]
    # @return [Hash]
    def fetch_config_params(key, base)
      [{}, :plugin_defaults].find do |context|
        ret = Config::Searcher.with_context(context) do
          Config.search(base)
        end
        if ret&.key?(key)
          return ret
        end
      end || {}
    end

    # @return [Hash] If check passes
    # @raise [InvalidFileError] If check does not pass
    def validate(path)
      duplicates = []
      YAMLDuplicationChecker.check(File.read(path), path) do |ignored, duplicate|
        MultiLogger.error "#{path}: #{ignored.value} is duplicated"
        duplicates << duplicate.value
      end
      raise InvalidFileError, "Detect duplicate keys #{duplicates}" unless duplicates.empty?

      yamls = YAML.load_stream(File.read(path)).compact
      yamls.map do |yaml|
        raise InvalidFileError, "invalid config.yml: #{path}" unless yaml.is_a? Hash

        yaml.deep_symbolize_keys
      end
    end

    # @param index [Index]
    def search(index)
      @searcher.search_with_cache(index, location: keymap)
    end

    # @param index [Config::Index]
    # @return Symbol
    def find_execute_key(index)
      @execute_keys ||= Plugin::Executors::Executor.plugins.map do |executor|
        executor.new.execute_keys
      end.flatten

      execute_params = search(index)
      return if execute_params.nil? || !execute_params.is_a?(Hash)

      @execute_keys.find { |k| execute_params.key?(k) }
    end

    private

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

    def expand_custom_path
      File.expand_path(custom_path)
    end

    def expand_config_path(filename)
      File.expand_path "~/.config/#{filename}"
    end

    def expand_default_path(filename)
      File.expand_path "../../#{filename}", __FILE__
    end

    def plugin_defaults_paths
      Plugin::Manager.load_paths.map do |plugin_path|
        yml = plugin_path.gsub(/\.rb$/, ".yml")
        yml if File.exist?(yml)
      end.compact
    end
  end
end
