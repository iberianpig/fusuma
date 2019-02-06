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

    def require_from_gem; end

    class << self
      attr_reader :plugins

      def add(plugin_class:)
        @plugins ||= {}
        @plugins[plugin_class.superclass.name] ||= []
        @plugins[plugin_class.superclass.name] << plugin_class
        puts "#{plugin_class.name} is added to #{name}"
      end
    end
  end

  class Plugin
    def self.inherited(subclass)
      PluginManager.add(plugin_class: subclass)
      PluginManager.new(path: plugin_dir_name(subclass: subclass)).require_plugins
    end

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
