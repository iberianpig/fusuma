module Fusuma
  # read keymap from yaml file
  class Config
    def initialize
      @keymap ||= YAML.load_file(file_path)
    end
    attr_reader :keymap

    def shortcut(gesture_info)
      action_type = gesture_info[:action_type]
      direction   = gesture_info[:direction]
      finger      = gesture_info[:finger].to_i
      key = seek_keyevent(action_type, direction, finger)
      MultiLogger.debug(key: key)
      key
    end

    private

    def seek_keyevent(action_type, direction, finger)
      seek_index = [action_type, finger, direction, 'shortcut']
      search_config(keymap, seek_index)
    end

    def search_config(keymap_node, seek_index)
      return keymap_node if seek_index == []
      key = seek_index.shift
      child_node = keymap_node[key]
      return search_config(child_node, seek_index) if child_node
      search_config(keymap_node, seek_index)
    end

    def file_path
      filename = 'fusuma/config.yml'
      original_path = File.expand_path "~/.config/#{filename}"
      default_path  = File.expand_path "../#{filename}", __FILE__
      File.exist?(original_path) ? original_path : default_path
    end
  end
end
