# frozen_string_literal: true

module Fusuma
  module Plugin
    module Formats
      module Records
        # Default Record Format
        class TextRecord < Record
          # @param text [String]
          def initialize(text)
            @text = text
          end

          def type
            :text
          end

          # @return [String]
          def to_s
            @text
          end
        end
      end
    end
  end
end
