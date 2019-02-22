module Fusuma
  module Plugin
    # Create a Plugin Class with extending this class
    class Base
      # if inherited from subclass
      def self.inherited(subclass)
        subclass_path = caller_locations(1..1).first.path
        Manager.add(plugin_class: subclass, plugin_path: subclass_path)
      end

      # get inherited classes
      # @example
      #  [Vectors::Vector]
      # @return [Array]
      def self.plugins
        Manager.plugins[name]
      end

      # @return [Input]
      def self.generate(options:)
        attr = name.gsub('Fusuma::', '')
                   .underscore
                   .split('/')
                   .last
        new options.fetch(attr.to_sym, {})
      end
    end
  end
end
