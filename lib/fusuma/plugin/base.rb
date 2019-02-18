module Fusuma
  module Plugin
    # Create a Plugin Class with extending this class
    class Base
      # if inherited from subclass
      def self.inherited(subclass)
        return unless Manager.add(plugin_class: subclass)

        Manager.new(path: plugin_dir_name(subclass: subclass)).require_plugins
      end

      # get inherited classes
      # @example
      #  [Vectors::BaseVector]
      # @return [Array]
      def self.plugins
        Manager.plugins[name]
      end

      def self.plugin_dir_name(subclass: self)
        subclass.namespace_name.underscore
      rescue StandardError
        subclass.name.match(/(Fusuma::.*)::/)[1].to_s.underscore
      end
    end
  end
end