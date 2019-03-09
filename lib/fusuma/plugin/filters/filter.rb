require_relative '../base.rb'

module Fusuma
  module Plugin
    # filter class
    module Filters
      # Inherite this base
      class Filter < Base
        attr_reader :options
        def initialize(options = {})
          @options = options
        end

        # @param event [Event]
        # @return [Event, nil]
        def filter(event)
          event.tap do |e|
            return nil if e.tag == source && filter_record?(event.record)
          end
        end

        def source
          @source ||= options.fetch(:source,
                                    self.class.const_get('DEFAULT_SOURCE'))
        end

        def filter_record?(record)
          device_ids.none? { |device_id| record =~ /^\s?#{device_id}/  }
        end
      end

      # Generate filter
      class Generator
        # DUMMY_OPTIONS = { filter: { dummy: 'dummy_options' } }.freeze
        # @param options [Hash]
        def initialize(options:)
          @options = options.fetch(:filters, {})
        end

        # Generate filter plugins
        # @return [Array]
        def generate
          plugins.map do |klass|
            klass.generate(options: @options)
          end.compact
        end

        # filter plugins
        # @return [Array]
        def plugins
          Filter.plugins
        end
      end
    end
  end
end
