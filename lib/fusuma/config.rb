module Fusuma
  # read keymap from yaml file
  class Config
    def initialize
      @keymap ||= YAML.load_file(file_path)
    end
    attr_reader :keymap

    def shortcut(action, direction, finger = nil)
      return keymap[action][direction]['shortcut'] if finger.nil?
      keymap[action][finger][direction]['shortcut']
    end

    private

    def file_path
      filename = 'fusuma/config.yml'
      original_path = File.expand_path "~/.config/#{filename}"
      default_path = File.expand_path "../#{filename}", __FILE__
      File.exist?(original_path) ? original_path : default_path
    end
  end
end
