require_relative '../multi_logger.rb'
require_relative '../config.rb'

module Fusuma
  module Plugin
    # Manage Fusuma plugins
    class Manager
      def initialize(plugin_class:, plugin_path:)
        @plugin_class = plugin_class
        @plugin_path = plugin_path
      end

      def require_plugins
        require_siblings_from_local
        require_siblings_from_gem
      end

      # # TODO: load path is defined in config.yml
      # def require_from_config
      #   Dir[File.join('lib', @path, '*.rb')].each do |file|
      #     next unless File.exist?(file)
      #
      #     base_path = 'lib/fusuma/plugin/'
      #     relative_path = file.gsub(base_path, '')
      #     require_relative(relative_path)
      #   end
      # end

      def require_siblings_from_local
        search_key = File.join('./lib', plugin_dir_name(plugin_class: @plugin_class), '*.rb')
        Dir.glob(search_key).each do |siblings_plugin|
          next if self.class.load_paths.include?(siblings_plugin)

          require './' + siblings_plugin
        end
      rescue LoadError => e
        MultiLogger.debug(e)
      end

      def require_siblings_from_gem
        search_key = File.join(plugin_dir_name(plugin_class: @plugin_class), '*.rb')
        Gem.find_files(search_key).each do |siblings_plugin|
          next if self.class.load_paths.include?(siblings_plugin)

          require siblings_plugin
        end
      rescue LoadError => e
        MultiLogger.debug(e)
      end

      def plugin_dir_name(plugin_class:)
        plugin_class.name.match(/(Fusuma::.*)::/)[1].to_s.underscore
      end

      class << self
        # @example
        #  Manager.plugins
        #  => {"Base"=>[Vectors::Vector],
        #      "Vectors::Vector"=>[Vectors::RotateVector,
        #                                      Vectors::PinchVector,
        #                                      Vectors::SwipeVector]}
        attr_reader :plugins
        attr_accessor :load_paths

        # @param plugin_class [Class]
        # return [Hash, false]
        def add(plugin_class:, plugin_path:)
          @plugins ||= {}
          return false if exist?(plugin_class: plugin_class)

          base = plugin_class.superclass.name
          @plugins[base] ||= []
          @plugins[base] << plugin_class

          @load_paths ||= []
          @load_paths << plugin_path

          Manager.new(plugin_class: plugin_class, plugin_path: plugin_path).require_plugins
        end

        # @param plugin_class [Class]
        # @return Boolean
        def exist?(plugin_class:)
          base = plugin_class.superclass.name
          return false if @plugins[base].nil?

          @plugins[base].any? do |registerd|
            registerd == plugin_class
          end
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
