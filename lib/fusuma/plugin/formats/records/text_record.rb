require_relative './record.rb'

module Fusuma
  module Plugin
    module Formats
      module Records
        # Default Record Format
        class Text < Record
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
