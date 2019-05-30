# frozen_string_literal: true

require_relative '../base.rb'

module Fusuma
  module Plugin
    # vector class
    module Vectors
      # Inherite this base
      class Vector < Base
        def initialize
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        def finger
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        def direction
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        def enough?
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # @return [Config::Index]
        def index
          Config::Index.new(
            [
              Config::Index::Key.new(self.class.type),
              Config::Index::Key.new(finger, skippable: true),
              Config::Index::Key.new(direction)
            ]
          )
        end

        class << self
          # @param event_buffer [EventBuffer]
          # @return [Vector]
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
        #  [Vectors::RotateVector, Vectors::PinchVector,
        #   Vectors::SwipeVector]
        # @return [Array]
        def plugins
          # NOTE: select vectors only defined in config.yml
          Vector.plugins.select do |klass|
            index = Config::Index.new(klass.type)
            Config.search(index)
          end
        end
      end
    end
  end
end
