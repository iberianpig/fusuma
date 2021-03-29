# frozen_string_literal: true

require_relative './multi_logger'
require_relative './libinput_command'

module Fusuma
  # detect input device
  class Device
    attr_reader :id, :name, :capabilities, :available

    def initialize(id: nil, name: nil, capabilities: nil, available: nil)
      @id = id
      @name = name
      @capabilities = capabilities
      @available = available
    end

    # @param attributes [Hash]
    def assign_attributes(attributes)
      attributes.each do |k, v|
        case k
        when :id
          @id = v
        when :name
          @name = v
        when :capabilities
          @capabilities = v
        when :available
          @available = v
        end
      end
    end

    class << self
      # Return devices
      # sort devices by capabilities of gesture
      # @return [Array]
      def all
        @all ||= fetch_devices.sort_by do |d|
          d.capabilities.match(/gesture/).to_s
        end
      end

      # @raise [SystemExit]
      # @return [Array]
      def available
        @available ||= all.select(&:available).tap do |d|
          MultiLogger.debug(available_devices: d)
          raise 'Touchpad is not found' if d.empty?
        end
      rescue RuntimeError => e
        # FIXME: should not exit without Runner class
        MultiLogger.error(e.message)
        exit 1
      end

      def reset
        @all = nil
        @available = nil
      end

      private

      # @return [Array]
      def fetch_devices
        line_parser = LineParser.new

        libinput_command = Plugin::Inputs::LibinputCommandInput.new.command
        libinput_command.list_devices do |line|
          line_parser.push(line)
        end
        line_parser.generate_devices
      end
    end

    # parse line and generate devices
    class LineParser
      attr_reader :lines

      def initialize
        @lines = []
      end

      # @param line [String]
      def push(line)
        lines.push(line)
      end

      # @return [Array]
      def generate_devices
        lines.each_with_object([]) do |line, devices|
          attributes = extract_attribute(line: line)

          next if attributes == {}

          if attributes[:name]
            # when detected new line including device name
            devices << Device.new # next device
          end

          devices.last.assign_attributes(attributes) unless devices.empty?
        end
      end

      # @param line [String]
      # @return [Hash]
      def extract_attribute(line:)
        if (id = id_from(line))
          { id: id }
        elsif (name = name_from(line))
          { name: name }
        elsif (capabilities = capabilities_from(line))
          { capabilities: capabilities }
        elsif (available = available_from(line))
          { available: available }
        else
          {}
        end
      end

      def id_from(line)
        line.match('^Kernel:[[:space:]]*') do |m|
          m.post_match.match(/event[0-9]+/).to_s
        end
      end

      def name_from(line)
        line.match('^Device:[[:space:]]*') do |m|
          m.post_match.strip
        end
      end

      def capabilities_from(line)
        line.match('^Capabilities:[[:space:]]*') do |m|
          m.post_match.strip
        end
      end

      def available_from(line)
        # NOTE: is natural scroll available?
        if line =~ /^Nat.scrolling: /
          return false if line =~ %r{n/a}

          return true # disabled / enabled
        end
        nil
      end
    end
  end
end
