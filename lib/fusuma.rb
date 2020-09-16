# frozen_string_literal: true

require_relative './fusuma/version'
require_relative './fusuma/multi_logger'
require_relative './fusuma/config.rb'
require_relative './fusuma/environment.rb'
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

        Plugin::Manager.require_base_plugins

        Environment.dump_information
        Kernel.exit(0) if option[:version]

        if option[:list]
          Environment.print_device_list
          Kernel.exit(0)
        end

        # TODO: remove keep_device_from_option from command line options
        Plugin::Filters::LibinputDeviceFilter::KeepDevice.from_option = option[:device]

        Process.daemon if option[:daemon]
      end

      def load_custom_config(config_path = nil)
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
      loop do
        event = input
        event || next
        clear_expired_events
        filtered = filter(event) || next
        parsed = parse(filtered) || next
        buffered = buffer(parsed) || next
        detected = detect(buffered) || next
        merged = merge(detected) || next
        execute(merged)
      end
    end

    def input
      Plugin::Inputs::Input.select(@inputs)
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

      l = lambda do
        executor = @executors.find { |e| e.executable?(event) }
        executor&.execute(event)
      end

      l.call ||
        Config::Searcher.skip { l.call } ||
        Config::Searcher.fallback { l.call } ||
        Config::Searcher.skip { Config::Searcher.fallback { l.call } }
    end

    def clear_expired_events
      @buffers.each(&:clear_expired)
    end
  end
end
