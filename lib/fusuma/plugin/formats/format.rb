# frozen_string_literal: true

require_relative '../base.rb'

module Fusuma
  module Plugin
    module Formats
      # @abstract Subclass and override {#initialize} to implement
      class Format < Base
        attr_reader :options

        def initialize(options: {})
          @options = options
        end

        def type
          self.class.name.underscore.split('/').last.gsub('_format', '')
        end
      end
    end
  end
end
