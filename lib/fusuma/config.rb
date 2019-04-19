# module as namespace
module Fusuma
  require 'singleton'
  # read keymap from yaml file
  class Config
    include Singleton

    class << self
      def shortcut(vector)
        instance.shortcut(vector)
      end

      def threshold(vector)
        instance.threshold(vector)
      end

      def interval(vector)
        instance.interval(vector)
      end

      def search(keys, klass = Object)
        instance.search(keys, klass)
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
      MultiLogger.info "reload config : #{file_path}"
      self
    end

    def shortcut(vector)
      keys = [*gesture_index(vector), 'shortcut']
      search(keys, String)
    end

    def threshold(vector)
      keys_specific = [*gesture_index(vector), 'threshold']
      keys_global = ['threshold', vector.class::TYPE]
      search(keys_specific, Numeric) || search(keys_global, Numeric) || 1
    end

    def interval(vector)
      keys_specific = [*gesture_index(vector), 'interval']
      keys_global = ['interval', vector.class::TYPE]
      search(keys_specific, Numeric) || search(keys_global, Numeric) || 1
    end

    # @param keys [Array]
    # @param klass [Class] class expected
    def search(keys, klass = Object)
      cache([*keys, klass]) do
        result = keys.reduce(keymap) do |location, key|
          if location.is_a?(Hash) && location.key?(key)
            location[key]
          else
            location
          end
        end
        result if result.is_a?(klass)
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

    def gesture_index(vector)
      gesture_type = vector.class::TYPE
      finger      = vector.finger
      direction   = vector.direction
      [gesture_type, finger, direction]
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
