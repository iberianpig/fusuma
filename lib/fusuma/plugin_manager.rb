require_relative './multi_logger.rb'

module Fusuma
  # Manage Fusuma plugins
  class PluginManager
    def initialize(path:)
      @path = path
    end

    def require_plugins
      require_from_lib
      require_from_gem
    end

    def require_from_lib
      Dir[File.join(__dir__, @path, '*.rb')].each do |file|
        require file
      end
    end

    # TODO: load from rubygems
    def require_from_gem; end

    class << self
      # @example
      #  Fusuma::PluginManager.plugins
      #  => {"Fusuma::Plugin"=>[Fusuma::Vectors::BaseVector],
      #      "Fusuma::Vectors::BaseVector"=>[Fusuma::Vectors::RotateVector,
      #                                      Fusuma::Vectors::PinchVector,
      #                                      Fusuma::Vectors::SwipeVector]}
      attr_reader :plugins

      # @param plugin_class [Class]
      def add(plugin_class:)
        @plugins ||= {}
        @plugins[plugin_class.superclass.name] ||= []
        @plugins[plugin_class.superclass.name] << plugin_class
      end
    end
  end

  # Create a Plugin Class with extending this class
  class Plugin
    # require_plugins
    def self.inherited(subclass)
      PluginManager.add(plugin_class: subclass)
      PluginManager.new(path: plugin_dir_name(subclass: subclass))
                   .require_plugins
    end

    # get inherited classes
    # @example
    #  [Fusuma::Vectors::BaseVector]
    # @return [Array]
    def self.plugins
      PluginManager.plugins[name]
    end

    def self.plugin_dir_name(subclass: self)
      subclass.name.match(/Fusuma::(.*)::/)[1].to_s.underscore
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
      .tr('-', '_')
      .downcase
  end
end
