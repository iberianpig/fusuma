require_relative '../base.rb'

module Fusuma
  module Plugin
    module Formats
      # @abstract Subclass and override {#initialize} to implement
      class Format < Base
        attr_reader :options

        def initialize(options = {})
          @options = options
        end

        def type
          self.class.name.underscore.split('/').last.gsub('_format', '')
        end
      end

      # Generate format
      class Generator
        # @param options [Hash]
        def initialize(options:)
          @options = options.fetch(:formats, {})
        end

        # Generate format
        # @return [Array<Format>]
        def generate
          plugins.map do |klass|
            klass.generate(options: @options)
          end.compact
        end

        # format plugins
        # @return [Array]
        def plugins
          Format.plugins
        end
      end
    end
  end
end
