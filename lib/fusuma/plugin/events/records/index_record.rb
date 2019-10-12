# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        # Vector Record
        # have index
        class IndexRecord < Record
          # define gesture format
          attr_reader :index

          # @param [Config::Index] index
          # @param [Symbol] position [:prefix, :body, :surfix]
          def initialize(index:, position: :body)
            @index = index
            @position = position
          end

          def type
            :index
          end

          # @param records [Array<IndexRecord>]
          # @return [IndexRecord]
          def merge(records:)
            raise "position is NOT body: #{self}" unless mergable?

            @index = records.each_with_object(@index) do |record, merged_index|
              case record.position
              when :prefix
                Index.new([*record.index.keys, *merged_index.keys])
              when :surfix
                Index.new([*merged_index.keys, *record.index.keys])
              else
                raise "invalid index position: #{record}"
              end
            end
            self
          end

          def mergable?
            @position == :body
          end

          protected

          attr_reader :position
        end
      end
    end
  end
end
