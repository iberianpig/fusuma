# frozen_string_literal: true

require "yaml"

module Fusuma
  class Config
    # ref: https://github.com/rubocop-hq/rubocop/blob/97e4ffc8a71e9e5239a927c6a534dfc1e0da917f/lib/rubocop/yaml_duplication_checker.rb
    # Find duplicated keys from YAML.
    # steep:ignore:start
    module YAMLDuplicationChecker
      #: (String, String) { (string) -> void }  -> void
      def self.check(yaml_string, filename, &on_duplicated)
        tree = YAML.parse(yaml_string, filename: filename)
        return unless tree

        traverse(tree, &on_duplicated)
      end

      #: (Psych::Nodes) { () -> void } -> Array[untyped]?
      def self.traverse(tree, &on_duplicated)
        case tree
        when Psych::Nodes::Mapping
          tree.children.each_slice(2).with_object([]) do |(key, value), keys|
            exist = keys.find { |key2| key2.value == key.value }
            on_duplicated.call(exist, key) if exist
            keys << key
            traverse(value, &on_duplicated)
          end
        else
          children = tree.children
          return unless children

          children.each { |c| traverse(c, &on_duplicated) }
        end
      end

      private_class_method :traverse
    end
    # steep:ignore:end
  end
end
