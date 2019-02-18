require_relative '../multi_logger.rb'
require_relative './base.rb'

module Fusuma
  module Plugin
    # Manage Fusuma plugins
    class Manager
      def initialize(path:)
        @path = path
      end

      def require_plugins
        require_from_local
        require_from_gem
      end

      # TODO: load plugins from local for developer
      def require_from_local
        Dir[File.join('lib', @path, '*.rb')].each do |file|
          next unless File.exist?(file)

          base_path = 'lib/fusuma/plugin/'
          relative_path = file.gsub(base_path, '')
          require_relative(relative_path)
        end
      end

      def require_from_gem
        require 'rubygems' unless defined? Gem

        Gem.find_files(File.join(@path, '*.rb')).each do |plugin_path|
          require plugin_path
        end
      rescue LoadError => e
        MultiLogger.debug(e)
      end

      class << self
        # @example
        #  Manager.plugins
        #  => {"Base"=>[Vectors::BaseVector],
        #      "Vectors::BaseVector"=>[Vectors::RotateVector,
        #                                      Vectors::PinchVector,
        #                                      Vectors::SwipeVector]}
        attr_reader :plugins

        # @param plugin_class [Class]
        def add(plugin_class:)
          @plugins ||= {}
          base = plugin_class.superclass.name
          @plugins[base] ||= []
          return false if @plugins[base].any? { |registerd| registerd == plugin_class }

          @plugins[base] << plugin_class
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
