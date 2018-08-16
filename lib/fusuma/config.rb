# module as namespace
module Fusuma
  require 'singleton'
  # read keymap from yaml file
  class Config
    include Singleton

    class << self
      def command(command_executor)
        instance.command(command_executor)
      end

      def shortcut(command_executor)
        instance.shortcut(command_executor)
      end

      def threshold(event_type, command_executor)
        instance.threshold(event_type, command_executor)
      end

      def interval(event_type, command_executor)
        instance.interval(event_type, command_executor)
      end

      def reload
        instance.reload
      end
    end

    attr_reader :keymap
    attr_accessor :custom_path

    def initialize
      @custom_path = nil
      reload
    end

    def reload
      @cache  = nil
      @keymap = YAML.load_file(file_path)
      self
    end

    def command(command_executor)
      seek_index = [*event_index(command_executor), 'command']
      search_config_cached(seek_index)
    end

    def shortcut(command_executor)
      seek_index = [*event_index(command_executor), 'shortcut']
      search_config_cached(seek_index)
    end

    def threshold(event_type, command_executor)
      seek_index_trigger = [*event_index(command_executor), 'threshold']
      seek_index_global = ['threshold', event_type]
      search_config_cached(seek_index_trigger) ||
        search_config_cached(seek_index_global) || 1
    end

    def interval(event_type, command_executor)
      seek_index_trigger = [*event_index(command_executor), 'interval']
      seek_index_global = ['interval', event_type]
      search_config_cached(seek_index_trigger) ||
        search_config_cached(seek_index_global) || 1
    end

    private

    def search_config_cached(seek_index)
      cache(seek_index) { search_config(keymap, seek_index) }
    end

    def search_config(keymap_node, seek_index)
      if seek_index == []
        return nil if keymap_node.is_a? Hash
        return keymap_node
      end
      key = seek_index[0]
      child_node = keymap_node[key]
      next_index = seek_index[1..-1]
      return search_config(child_node, next_index) if child_node
      search_config(keymap_node, next_index)
    end

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

    def event_index(command_executor)
      event_type = command_executor.event_type
      finger      = command_executor.finger
      direction   = command_executor.direction
      [event_type, finger, direction]
    end

    def cache(key)
      @cache ||= {}
      key = key.join(',') if key.is_a? Array
      @cache[key] ||= block_given? ? yield : nil
    end
  end
end
