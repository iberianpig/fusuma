module Fusuma
  # detect input device
  class Device
    class << self
      attr_writer :names

      def names
        return @names unless no_name?
        device_names = fetch_device_names
        MultiLogger.debug(device_names: device_names)
        raise 'Touchpad is not found' if device_names.empty?
        @names = device_names
      rescue RuntimeError => ex
        MultiLogger.error(ex.message)
        exit 1
      end

      # @params [String]
      def given_device=(name)
        return if name.nil?
        if names.include? name
          self.names = [name]
          return
        end
        MultiLogger.error("Device #{name} is not found")
        exit 1
      end

      private

      def no_name?
        @names.nil? || @names.empty?
      end

      # @return [Array]
      def fetch_device_names
        [].tap do |devices|
          current_device = nil
          LibinputCommands.new.list_devices do |line|
            current_device = extracted_input_device_from(line) || current_device
            next unless natural_scroll_is_available?(line)
            devices << current_device
          end
        end.compact
      end

      def extracted_input_device_from(line)
        return unless line =~ /^Kernel: /
        line.match(/event[0-9]+/).to_s
      end

      def natural_scroll_is_available?(line)
        return false unless line =~ /^Nat.scrolling: /
        return false if line =~ %r{n/a}
        true
      end
    end
  end
end
