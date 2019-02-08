require_relative './plugin_manager.rb'

module Fusuma
  # input class
  module Inputs
    # Inherite this base
    class BaseInput < Plugin
      def initialize; end

      def run; end

      class << self
        # @return [BaseInput]
        def generate; end
      end
    end

    # Generate input
    class Generator
      DUMMY_OPTIONS = { input: { libinput_command: '--enable-tap' } }.freeze
      # @param options [Hash]
      def initialize(options: DUMMY_OPTIONS)
        @options = options
      end

      # and generate input
      # @return [input]
      def generate
        plugins.map do |klass|
          klass.generate(options: @options)
        end.compact.first
      end

      # input plugins
      # @retrun [Array]
      def plugins
        BaseInput.plugins
      end
    end
  end
end
