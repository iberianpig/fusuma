# frozen_string_literal: true

require_relative './fusuma/version'
require_relative './fusuma/multi_logger'
require_relative './fusuma/config.rb'
require_relative './fusuma/device.rb'
require_relative './fusuma/plugin/manager.rb'

# this is top level module
module Fusuma
  # main class
  class Runner
    class << self
      def run(option = {})
        set_trap
        read_options(option)
        instance = new
        instance.run
      end

      private

      def set_trap
        Signal.trap('INT') { puts exit } # Trap ^C
        Signal.trap('TERM') { puts exit } # Trap `Kill `
      end

      def read_options(option)
        MultiLogger.instance.debug_mode = option[:verbose]

        load_custom_config(option[:config_path])

        Plugin::Manager.require_plugins_from_relative

        MultiLogger.info '---------------------------------------------'
        print_version
        MultiLogger.info '---------------------------------------------'
        print_enabled_plugins
        MultiLogger.info '---------------------------------------------'
        Kernel.exit(0) if option[:version]

        print_device_list if option[:list]
        # TODO: remove keep_device_from_option from command line options
        Plugin::Filters::LibinputDeviceFilter::KeepDevice.from_option = option[:device]
        Process.daemon if option[:daemon]
      end

      def print_version
        MultiLogger.info "Fusuma: #{Fusuma::VERSION}"
        MultiLogger.info "libinput: #{Plugin::Inputs::LibinputCommandInput.new.version}"
        MultiLogger.info "OS: #{`uname -rsv`}".strip
        MultiLogger.info "Distribution: #{`cat /etc/issue`}".strip
        MultiLogger.info "Desktop session: #{`echo $DESKTOP_SESSION $XDG_SESSION_TYPE`}".strip
      end

      def print_enabled_plugins
        MultiLogger.info 'Enabled Plugins: '
        Plugin::Manager.plugins
                       .reject { |k, _v| k.to_s =~ /Base/ }
                       .map { |_base, plugins| plugins.map { |plugin| "  #{plugin}" } }
                       .flatten.sort.each { |name| MultiLogger.info(name) }
      end

      def print_device_list
        puts Device.available.map(&:name)
        exit(0)
      end

      def load_custom_config(config_path = nil)
        return unless config_path

        Config.custom_path = config_path
      end
    end

    def initialize
      @inputs = Plugin::Inputs::Input.plugins.map(&:new)
      @filters = Plugin::Filters::Filter.plugins.map(&:new)
      @parsers = Plugin::Parsers::Parser.plugins.map(&:new)
      @buffers = Plugin::Buffers::Buffer.plugins.map(&:new)
      @detectors = Plugin::Detectors::Detector.plugins.map(&:new)
      @executors = Plugin::Executors::Executor.plugins.map(&:new)
    end

    def run
      # TODO: run with multi thread
      @inputs.first.run do |event|
        clear_expired
        filtered = filter(event) || next
        parsed = parse(filtered) || next
        buffered = buffer(parsed) || next
        detected = detect(buffered) || next
        merged = merge(detected) || next
        execute(merged)
      end
    end

    def filter(event)
      event if @filters.any? { |f| f.filter(event) }
    end

    def parse(event)
      @parsers.reduce(event) { |e, p| p.parse(e) if e }
    end

    def buffer(event)
      @buffers.any? { |b| b.buffer(event) } && @buffers
    end

    # @param buffers [Array<Buffer>]
    # @return [Array<Event>]
    def detect(buffers)
      @detectors.each_with_object([]) do |detector, detected|
        if (event = detector.detect(buffers))
          detected << event
        end
      end
    end

    # @param events [Array<Event>]
    # @return [Event] a Event merged all records from arguments
    # @return [NilClass] when event is NOT given
    def merge(events)
      main_events, modifiers = events.partition { |event| event.record.mergable? }
      return nil unless (main_event = main_events.first)

      main_event.record.merge(records: modifiers.map(&:record))
      main_event
    end

    def execute(event)
      return unless event

      executor = @executors.find do |e|
        e.executable?(event)
      end

      executor&.execute(event)
    end

    def clear_expired
      @buffers.each(&:clear_expired)
    end
  end
end
