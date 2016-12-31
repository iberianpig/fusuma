module Fusuma
  # read keymap from yaml file
  class Config
    include Singleton
    def initialize
      @keymap ||= YAML.load_file(file_path)
    end
    attr_reader :keymap

    def shortcut(gesture_info)
      seek_index = [*action_index(gesture_info), 'shortcut']
      cache(seek_index) { search_config(keymap, seek_index) }
    end

    def threshold(action_type)
      seek_index = ['threshold', action_type]
      cache(seek_index) { search_config(keymap, seek_index) } || 1
    end

    private

    def search_config(keymap_node, seek_index)
      if seek_index == []
        return nil if keymap_node.is_a? Hash
        return keymap_node
      end
      key = seek_index.shift
      child_node = keymap_node[key]
      return search_config(child_node, seek_index) if child_node
      search_config(keymap_node, seek_index)
    end

    def file_path
      filename = 'fusuma/config.yml'
      original_path = File.expand_path "~/.config/#{filename}"
      default_path  = File.expand_path "../../#{filename}", __FILE__
      File.exist?(original_path) ? original_path : default_path
    end

    def action_index(gesture_info)
      action_type = gesture_info.action_type
      finger      = gesture_info.finger
      direction   = gesture_info.direction
      [action_type, finger, direction]
    end

    def cache(key)
      @cache ||= {}
      key = key.join(',') if key.is_a? Hash
      @cache[key] ||= yield
    end
  end
end
