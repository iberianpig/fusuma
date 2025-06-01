# frozen_string_literal: true

require_relative "record"

module Fusuma
  module Plugin
    module Events
      module Records
        # Default Record
        class TextRecord < Record
          # @param text [String]
          #: (String) -> void
          def initialize(text)
            super()
            @text = text
          end

          #: () -> Symbol
          def type
            :text
          end

          # @return [String]
          #: () -> String
          def to_s
            @text
          end
        end
      end
    end
  end
end
