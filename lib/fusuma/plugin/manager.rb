# frozen_string_literal: true

require_relative '../multi_logger.rb'

module Fusuma
  module Plugin
    # Manage Fusuma plugins
    class Manager
      def initialize(plugin_class)
        @plugin_class = plugin_class
      end

      def require_siblings_from_local
        search_key = File.join('./lib', plugin_dir_name, '*.rb')
        Dir.glob(search_key).each do |siblings_plugin|
          require './' + siblings_plugin
        end
      end

      def require_siblings_from_gems
        search_key = File.join(plugin_dir_name, '*.rb')
        Gem.find_files(search_key).each do |siblings_plugin|
          if siblings_plugin =~ %r{fusuma-plugin-(.+).*/lib/#{plugin_dir_name}/\1_.+.rb}
            require siblings_plugin
          end
        end
      end

      private

      def plugin_dir_name
        @plugin_class.name.match(/(Fusuma::.*)::/)[1].to_s.underscore
      end

      class << self
        # @example
        #  Manager.plugins
        #  => {"Base"=>[Detectors::Detector],
        #      "Detectors::Detector"=>[Detectors::RotateDetector,
        #                              Detectors::PinchDetector,
        #                              Detectors::SwipeDetector]}

        # @param plugin_class [Class]
        # return [Hash, false]
        def add(plugin_class:, plugin_path:)
          return false if exist?(plugin_class: plugin_class, plugin_path: plugin_path)

          base = plugin_class.superclass.name
          plugins[base] ||= []
          plugins[base] << plugin_class

          load_paths << plugin_path

          manager = Manager.new(plugin_class)
          manager.require_siblings_from_local
          manager.require_siblings_from_gems
        end

        def require_plugins_from_relative
          require_relative './base.rb'
          require_relative './events/event.rb'
          require_relative './inputs/input.rb'
          require_relative './filters/filter.rb'
          require_relative './parsers/parser.rb'
          require_relative './buffers/buffer.rb'
          require_relative './detectors/detector.rb'
          require_relative './executors/executor.rb'
        end

        def require_plugins_from_config
          local_plugin_paths = Config.search(Config::Index.new('local_plugin_paths'))
          return unless local_plugin_paths

          Array.new(local_plugin_paths).each do |plugin_path|
            require plugin_path
          end
        end

        def plugins
          @plugins ||= {}
        end

        def load_paths
          @load_paths ||= []
        end

        # @param plugin_class [Class]
        # @return [Boolean]
        def exist?(plugin_class:, plugin_path:)
          return false if load_paths.include?(plugin_path)

          base = plugin_class.superclass.name
          return false unless plugins[base]

          plugins[base].include?(plugin_class)
        end
      end
    end
  end
end

# support camerize and underscore
class String
  def camerize
    split('_').map do |w|
      w[0].upcase!
      w
    end.join
  end

  def underscore
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .gsub('::', '/')
      .tr('-', '_')
      .downcase
  end
end
