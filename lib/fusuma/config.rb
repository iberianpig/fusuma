# module as namespace
module Fusuma
  require 'singleton'
  # read keymap from yaml file
  class Config
    include Singleton

    class << self
      def command(event_trigger)
        instance.command(event_trigger)
      end

      def shortcut(event_trigger)
        instance.shortcut(event_trigger)
      end

      def threshold(action_type)
        instance.threshold(action_type)
      end

      def interval(action_type)
        instance.interval(action_type)
      end

      def misc(value)
        instance.misc(value)
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

    def command(event_trigger)
      seek_index = [*action_index(event_trigger), 'command']
      cache(seek_index) { search_config(keymap, seek_index) }
    end

    def shortcut(event_trigger)
      seek_index = [*action_index(event_trigger), 'shortcut']
      cache(seek_index) { search_config(keymap, seek_index) }
    end
    
    def threshold(action_type)
      seek_index = ['threshold', action_type]
      cache(seek_index) { search_config(keymap, seek_index) } || 1
    end

    def interval(action_type)
      seek_index = ['interval', action_type]
      cache(seek_index) { search_config(keymap, seek_index) } || 1
    end

    def misc(value)
      seek_index = ['misc', value]
      cache(seek_index) { search_config(keymap, seek_index) } || false
    end
    
    private

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

    def action_index(event_trigger)
      action_type = event_trigger.action_type
      finger      = event_trigger.finger
      direction   = event_trigger.direction
      [action_type, finger, direction]
    end

    def cache(key)
      @cache ||= {}
      key = key.join(',') if key.is_a? Array
      @cache[key] ||= block_given? ? yield : nil
    end
  end
end
