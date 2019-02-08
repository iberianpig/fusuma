require_relative './plugin_manager.rb'

module Fusuma
  # filter class
  module Filters
    # Inherite this base
    class BaseFilter < Plugin
      def initialize; end

      def filter; end

      class << self
        # @return [BaseFilter]
        def generate; end
      end
    end

    # Generate filter
    class Generator
      DUMMY_OPTIONS = { filter: { dummy: 'dummy_options' } }.freeze
      # @param options [Hash]
      def initialize(options: DUMMY_OPTIONS)
        @options = options
      end

      # and generate filter
      # @return [filter]
      def generate
        plugins.map do |klass|
          klass.generate(options: @options)
        end.compact.first
      end

      # filter plugins
      # @retrun [Array]
      def plugins
        BaseFilter.plugins
      end
    end
  end
end
