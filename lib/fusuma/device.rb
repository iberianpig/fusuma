module Fusuma
  # detect input device
  class Device
    attr_accessor :id
    attr_accessor :name
    attr_accessor :available

    def initialize(id: nil, name: nil, available: nil)
      @id = id
      @name = name
      @available = available
    end

    class << self
      # @return [Array]
      def ids
        available.map(&:id)
      end

      # @return [Array]
      def names
        available.map(&:name)
      end

      # @raise [SystemExit]
      # @return [Array]
      def available
        @available ||= fetch_available.tap do |d|
          MultiLogger.debug(available_devices: d)
          raise 'Touchpad is not found' if d.empty?
        end
      rescue RuntimeError => ex
        MultiLogger.error(ex.message)
        exit 1
      end

      def reset
        @available = nil
      end

      # @params [String]
      def given_device=(name)
        return if name.nil?
        @available = available.select { |d| d.name == name }
        return unless names.empty?
        MultiLogger.error("Device #{name} is not found.\n
           Check available device with: $ fusuma --list-devices\n")
        exit 1
      end

      private

      # @return [Array]
      def fetch_available
        line_parser = LineParser.new
        LibinputCommands.new.list_devices do |line|
          line_parser.push(line)
        end
        line_parser.generate_devices
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

        def generate_devices
          device = nil
          lines.each_with_object([]) do |line, devices|
            device ||= Device.new
            device = parse(device: device, line: line)
            if device.available
              devices << device
              device = nil
            end
          end
        end

        # @return [Device]
        def parse(device:, line:)
          if (id = id_from(line))
            device.id = id
          elsif (name = name_from(line))
            device.name = name
          elsif (available = natural_scroll_is_available?(line))
            device.available = available
          end
          device
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

        def natural_scroll_is_available?(line)
          return false unless line =~ /^Nat.scrolling: /
          return false if line =~ %r{n/a}
          true
        end
      end
    end
  end
end
