# frozen_string_literal: true

require_relative "../multi_logger"
require_relative "../string_support"

module Fusuma
  module Plugin
    # Manage Fusuma plugins
    class Manager
      def initialize(plugin_class)
        @plugin_class = plugin_class
      end

      def require_siblings_from_plugin_dir
        fusuma_default_plugin_paths.each { |siblings_plugin| require(siblings_plugin) }
      end

      def fusuma_default_plugin_paths
        search_key = File.join("../../", plugin_dir_name, "*.rb")
        Dir.glob(File.expand_path("#{__dir__}/#{search_key}")).sort
      end

      def require_siblings_from_gems
        fusuma_external_plugin_paths.each { |siblings_plugin| require(siblings_plugin) }
      end

      def fusuma_external_plugin_paths
        search_key = File.join(plugin_dir_name, "*.rb")
        Gem.find_latest_files(search_key).map do |siblings_plugin|
          next unless %r{fusuma-plugin-(.+).*/lib/#{plugin_dir_name}/.+\.rb}.match?(siblings_plugin)

          match_data = siblings_plugin.match(%r{(.*)/(.*)/lib/(.*)})
          gemspec_path = Dir.glob("#{match_data[1]}/#{match_data[2]}/*.gemspec").first
          raise "Not Found: #{match_data[1]}/#{match_data[2]}/*.gemspec" unless gemspec_path

          gemspec = Gem::Specification.load(gemspec_path)
          fusuma_gemspec_path = File.expand_path("../../../fusuma.gemspec", __dir__)
          fusuma_gemspec = Gem::Specification.load(fusuma_gemspec_path)

          if gemspec.dependencies.find { |d| d.name == "fusuma" }&.match?(fusuma_gemspec)
            siblings_plugin
          else
            MultiLogger.warn "#{gemspec.name} #{gemspec.version} is incompatible with running #{fusuma_gemspec.name} #{fusuma_gemspec.version}"
            MultiLogger.warn "gemspec: #{gemspec_path}"
            next
          end
        end.compact
      end

      private

      # @example
      #  plugin_dir_name
      #   => "fusuma/plugin/detectors"
      # @return [String]
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
          manager.require_siblings_from_plugin_dir
          manager.require_siblings_from_gems
        end

        def require_base_plugins
          require_relative "./base"
          require_relative "./events/event"
          require_relative "./inputs/input"
          require_relative "./filters/filter"
          require_relative "./parsers/parser"
          require_relative "./buffers/buffer"
          require_relative "./detectors/detector"
          require_relative "./executors/executor"
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
