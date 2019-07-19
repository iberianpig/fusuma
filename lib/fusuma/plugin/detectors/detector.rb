# frozen_string_literal: true

require_relative '../base.rb'

module Fusuma
  module Plugin
    # vector class
    module Detectors
      # Inherite this base
      class Detector < Base
        # @return Event
        def detect(buffers)
          buffers.each do |buffer|
            if type == buffer.type
            end
          end
        end

        def type
          'libinput'
        end

        class << self
          # @param _event_buffer [EventBuffer]
          # @return [Detector]
          def generate(_event_buffer:)
            raise NotImplementedError, "override #{self.class.name}.#{__method__}"
          end

          def type
            name.underscore.split('/').last.gsub('_vector', '')
          end

          def touch_last_time
            @last_time = Time.now
          end
        end
      end

      # Generate vector
      class Generator
        class << self
          attr_writer :prev_vector
          attr_reader :prev_vector
        end

        # @param event_buffer [EventBuffer]
        def initialize(event_buffer:)
          @event_buffer = event_buffer
        end

        # Generate vector
        # @return [vector]
        def generate
          plugins.map do |klass|
            klass.generate(event_buffer: @event_buffer)
          end.compact.first
        end

        # vector plugins
        # @example
        #  [Detectors::RotateDetector, Detectors::PinchDetector,
        #   Detectors::SwipeDetector]
        # @return [Array]
        def plugins
          # NOTE: select vectors only defined in config.yml
          Detector.plugins.select do |klass|
            index = Config::Index.new(klass.type)
            Config.search(index)
          end
        end
      end
    end
  end
end
