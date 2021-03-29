# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        # Context Record
        class ContextRecord < Record
          # define gesture format
          attr_reader :name, :value

          # @param name [#to_sym]
          # @param value [String]
          def initialize(name:, value:)
            super()
            @name = name.to_sym
            @value = value
          end

          def type
            :context
          end
        end
      end
    end
  end
end
