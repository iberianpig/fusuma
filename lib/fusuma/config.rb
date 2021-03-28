# frozen_string_literal: true

require_relative './multi_logger'
require_relative './config/index'
require_relative './config/searcher'
require_relative './config/yaml_duplication_checker'
require_relative './hash_support'
require 'singleton'
require 'yaml'

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
      @searcher = Searcher.new
      path = find_filepath
      MultiLogger.info "reload config: #{path}"
      @keymap = validate(path)
      self
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
      yamls.map(&:deep_symbolize_keys)
    rescue StandardError => e
      MultiLogger.error e.message
      raise InvalidFileError, e.message
    end

    # @param index [Index]
    # @param context [Hash]
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
      return if execute_params.nil?

      @execute_keys.find { |k| execute_params.keys.include?(k) }
    end

    private

    def find_filepath
      filename = 'fusuma/config.yml'
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
  end
end
