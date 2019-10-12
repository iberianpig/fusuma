# frozen_string_literal: true

require_relative './multi_logger.rb'
require_relative './config/index.rb'
require 'singleton'
require 'yaml'

# module as namespace
module Fusuma
  # read keymap from yaml file
  class Config
    include Singleton

    class << self
      def search(keys)
        instance.search(keys)
      end

      def custom_path=(new_path)
        instance.custom_path = new_path
      end
    end

    attr_reader :keymap
    attr_reader :custom_path

    def initialize
      @custom_path = nil
      @cache = nil
      @keymap = nil
      reload
    end

    def custom_path=(new_path)
      @custom_path = new_path
      reload
    end

    def reload
      @cache  = nil
      @keymap = YAML.load_file(file_path).deep_symbolize_keys
      MultiLogger.info "reload config : #{file_path}"
      self
    end

    # @param index [Index]
    def search(index)
      cache(index.cache_key) do
        index.keys.reduce(keymap) do |location, key|
          if location.is_a?(Hash)
            begin
              if key.skippable
                location.fetch(key.symbol, location)
              else
                location.fetch(key.symbol, nil)
              end
            end
          else
            location
          end
        end
      end
    end

    private

    def file_path
      filename = 'fusuma/config.yml'
      if custom_path && File.exist?(expand_custom_path)
        expand_custom_path
      elsif File.exist?(expand_config_path(filename))
        expand_config_path(filename)
      else
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

    def cache(key)
      @cache ||= {}
      key = key.join(',') if key.is_a? Array
      if @cache.key?(key)
        @cache[key]
      else
        @cache[key] = block_given? ? yield : nil
      end
    end
  end
end

# activesupport-4.1.1/lib/active_support/core_ext/hash/keys.rb
class Hash
  def deep_symbolize_keys
    deep_transform_keys do |key|
      begin
        key.to_sym
      rescue StandardError
        key
      end
    end
  end

  def deep_transform_keys(&block)
    result = {}
    each do |key, value|
      result[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys(&block) : value
    end
    result
  end
end
