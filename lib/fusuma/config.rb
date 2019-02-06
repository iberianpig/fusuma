# module as namespace
module Fusuma
  require 'singleton'
  # read keymap from yaml file
  class Config
    include Singleton

    class << self
      def command(vector)
        instance.command(vector)
      end

      def shortcut(vector)
        instance.shortcut(vector)
      end

      def threshold(vector)
        instance.threshold(vector)
      end

      def interval(vector)
        instance.interval(vector)
      end

      def reload
        instance.reload
      end
    end

    attr_reader :keymap
    attr_accessor :custom_path

    def initialize
      self.custom_path = nil
      reload
    end

    def reload
      @cache  = nil
      @keymap = YAML.load_file(file_path)
      self
    end

    def command(vector)
      keys = [*gesture_index(vector), 'command']
      search_config_cached(keys)
    end

    def shortcut(vector)
      keys = [*gesture_index(vector), 'shortcut']
      search_config_cached(keys)
    end

    def threshold(vector)
      keys_specific = [*gesture_index(vector), 'threshold']
      keys_global = ['threshold', vector.class::TYPE]
      search_config_cached(keys_specific) ||
        search_config_cached(keys_global) || 1
    end

    def interval(vector)
      keys_specific = [*gesture_index(vector), 'interval']
      keys_global = ['interval', vector.class::TYPE]
      search_config_cached(keys_specific) ||
        search_config_cached(keys_global) || 1
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

    def gesture_index(vector)
      gesture_type = vector.class::TYPE
      finger      = vector.finger
      direction   = vector.direction
      [gesture_type, finger, direction]
    end

    def search_config_cached(keys)
      cache(keys) { search_config(keymap, keys) }
    end

    def search_config(keymap_node, keys)
      if keys == []
        return nil if keymap_node.is_a? Hash

        return keymap_node
      end
      child_node = keymap_node[keys[0]]
      next_index = keys[1..-1]
      return search_config(child_node, next_index) if child_node

      search_config(keymap_node, next_index)
    end

    def cache(key)
      @cache ||= {}
      key = key.join(',') if key.is_a? Array
      @cache[key] ||= block_given? ? yield : nil
    end
  end
end
