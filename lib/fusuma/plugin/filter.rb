require_relative './manager.rb'

module Fusuma
  module Plugin
    # filter class
    module Filters
      # Inherite this base
      class Filter < Base
        def initialize(options); end

        def filter; end
      end

      # Generate filter
      class Generator
        # DUMMY_OPTIONS = { filter: { dummy: 'dummy_options' } }.freeze
        # @param options [Hash]
        def initialize(options:)
          @options = options.fetch(:filters, {})
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
          Filter.plugins
        end
      end
    end
  end
end
