# frozen_string_literal: true

require_relative "fusuma/version"
require_relative "fusuma/multi_logger"
require_relative "fusuma/config"
require_relative "fusuma/environment"
require_relative "fusuma/device"
require_relative "fusuma/plugin/manager"

# this is top level module
module Fusuma
  # main class
  class Runner
    class << self
      #: (?Hash[untyped, untyped]) -> nil
      def run(option = {})
        read_options(option)
        instance = new
        instance.set_trap
        instance.initialize_plugins
        ## NOTE: Uncomment following line to measure performance
        # instance.run_with_lineprof
        instance.run
      ensure
        instance&.send(:shutdown)
      end

      private

      #: (Hash[untyped, untyped]) -> void
      def read_options(option)
        MultiLogger.filepath = option[:log_filepath]
        MultiLogger.instance.debug_mode = option[:verbose]

        Plugin::Manager.require_base_plugins

        load_custom_config(option[:config_path])

        Environment.dump_information
        Kernel.exit(0) if option[:version]

        if option[:show_config]
          Environment.print_config
          Kernel.exit(0)
        end

        if option[:list]
          Environment.print_device_list
          Kernel.exit(0)
        end

        # TODO: remove keep_device_from_option from command line options
        Plugin::Filters::LibinputDeviceFilter::KeepDevice.from_option = option[:device]

        Process.daemon if option[:daemon]
      end

      #: (?Tempfile?) -> void
      def load_custom_config(config_path = nil)
        Config.custom_path = config_path
      end
    end

    #: () -> void
    def initialize
    end

    #: () -> void
    def initialize_plugins
      @inputs = Plugin::Inputs::Input.plugins.map do |cls|
        cls.ancestors.include?(Singleton) ? cls.instance : cls.new
      end
      @filters = Plugin::Filters::Filter.plugins.map(&:new)
      @parsers = Plugin::Parsers::Parser.plugins.map(&:new)
      @buffers = Plugin::Buffers::Buffer.plugins.map(&:new)
      @detectors = Plugin::Detectors::Detector.plugins.map(&:new)
      @executors = Plugin::Executors::Executor.plugins.map(&:new)
    end

    #: (?Hash[untyped, untyped]) -> nil
    def run
      loop { pipeline }
    end

    def pipeline
      event = input || return
      clear_expired_events
      filtered = filter(event) || return
      parsed = parse(filtered) || return
      buffered = buffer(parsed) || return
      detected = detect(buffered) || return
      context, event = merge(detected) || return
      execute(context, event)
    end

    # For performance monitoring
    def run_with_lineprof(count: 1000)
      require "rblineprof"
      require "rblineprof-report"

      profile = lineprof(%r{#{Pathname.new(__FILE__).parent}/.}) do
        count.times { pipeline }
      end
      LineProf.report(profile)
      exit 0
    end

    # @return [Plugin::Events::Event]
    def input
      Plugin::Inputs::Input.select(@inputs)
    end

    # @param [Plugin::Events::Event]
    # @return [Plugin::Events::Event]
    # @return [NilClass]
    def filter(event)
      event if @filters.any? { |f| f.filter(event) }
    end

    # @param [Plugin::Events::Event]
    # @return [Plugin::Events::Event]
    # @return [NilClass]
    def parse(event)
      @parsers.reduce(event) { |e, p| p.parse(e) if e }
    end

    # @param [Plugin::Events::Event]
    # @return [Array<Plugin::Buffers::Buffer>]
    # @return [NilClass]
    def buffer(event)
      @buffers.select { |b| b.buffer(event) }
    end

    # @param buffers [Array<Buffer>]
    # @return [Array<Event>]
    # @return [NilClass]
    def detect(buffers)
      matched_detectors = @detectors.select do |detector|
        detector.watch? ||
          buffers.any? { |b| detector.sources.include?(b.type) }
      end

      events = matched_detectors.each_with_object([]) do |detector, detected|
        # Array(detector.detect(@buffers)).each { |e| detected << e }
        detected.concat(Array(detector.detect(@buffers)))
      end

      return if events.empty?

      events
    end

    # @param events [Array<Plugin::Events::Event>]
    # @return [Array<Hash, Plugin::Events::Event>] Event merged all events from arguments and used context
    # @return [NilClass] when event is NOT given
    def merge(events)
      index_events, context_events = events.partition { |event| event.record.type == :index }
      main_events, modifiers = index_events.partition { |event| event.record.mergeable? }
      request_context = context_events.each_with_object({}) do |e, results|
        results[e.record.name] = e.record.value
      end
      main_events.sort_by! { |e| e.record.trigger_priority }

      matched_context = nil
      event = main_events.find do |main_event|
        matched_context = Config::Searcher.find_context(request_context) do
          if (modified_record = main_event.record.merge(records: modifiers.map(&:record)))
            main_event.record = modified_record
          elsif !modifiers.empty?
            # try basically the same, but without any modifiers
            # if modifiers is empty then we end up here only if there is no execute key for this
            Config.instance.search(main_event.record.index) &&
              Config.instance.find_execute_key(main_event.record.index)
          end
        end
      end
      return if event.nil?

      [matched_context, event]
    end

    # @return [NilClass] when event is NOT given or executable context is NOT found
    # @param event [Plugin::Events::Event]
    def execute(context, event)
      return unless event

      # Find executable context
      Config::Searcher.with_context(context) do
        executor = @executors.find { |e| e.executable?(event) }
        if executor
          # Check interval and execute
          executor.enough_interval?(event) &&
            executor.update_interval(event) &&
            executor.execute(event)
        end
      end
    end

    def clear_expired_events
      @buffers.each(&:clear_expired)
    end

    #: () -> void
    def set_trap
      Signal.trap("INT") {
        shutdown
        exit
      } # Trap ^C
      Signal.trap("TERM") {
        shutdown
        exit 1
      } # Trap `Kill `
    end

    private

    #: () -> Array[untyped]
    def shutdown
      [@inputs, @filters, @parsers, @buffers, @detectors, @executors].flatten.compact.each do |plugin|
        plugin.shutdown
      end
    end
  end
end
