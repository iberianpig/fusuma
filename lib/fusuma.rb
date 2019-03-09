require_relative './fusuma/version'
require_relative './fusuma/event_buffer'
require_relative './fusuma/vector_buffer'
require_relative './fusuma/multi_logger'
require_relative './fusuma/config.rb'
require_relative './fusuma/device.rb'
require_relative './fusuma/plugin/inputs/input.rb'
require_relative './fusuma/plugin/filters/filter.rb'
require_relative './fusuma/plugin/parsers/parser.rb'

require 'logger'
require 'open3'
require 'yaml'

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
        print_version && exit(0) if option[:version]
        reload_custom_config(option[:config_path])
        print_device_list if option[:list]
        debug_mode if option[:verbose]
        Device.given_device = option[:device]
        Process.daemon if option[:daemon]
      end

      def print_version
        MultiLogger.info '---------------------------------------------'
        MultiLogger.info "Fusuma: #{Fusuma::VERSION}"
        MultiLogger.info "libinput: #{Plugin::Inputs::LibinputCommandInput.new.version}"
        MultiLogger.info "OS: #{`uname -rsv`}".strip
        MultiLogger.info "Distribution: #{`cat /etc/issue`}".strip
        MultiLogger.info "Desktop session: #{`echo $DESKTOP_SESSION`}".strip
        MultiLogger.info '---------------------------------------------'
      end

      def enabled_plugins
        MultiLogger.info 'Enabled Plugins: '
        Plugin::Manager.plugins
                       .reject { |k, _v| k.to_s =~ /Base/ }
                       .map { |_base, plugins| plugins.map { |plugin| "  #{plugin}" } }
                       .flatten.sort.each { |name| MultiLogger.info name }
        MultiLogger.info '---------------------------------------------'
      end

      def print_device_list
        puts Device.names
        exit(0)
      end

      def reload_custom_config(config_path = nil)
        return unless config_path

        Config.instance.custom_path = config_path
        Config.reload
      end

      def debug_mode
        print_version
        enabled_plugins
        MultiLogger.instance.debug_mode = true
      end
    end

    def initialize
      @inputs = Plugin::Inputs::Generator.new(options: plugin_options).generate
      @filters = Plugin::Filters::Generator.new(options: plugin_options).generate
      @parsers = Plugin::Parsers::Generator.new(options: plugin_options).generate
      @event_buffer = EventBuffer.new
      @vector_buffer = VectorBuffer.new
    end

    def plugin_options
      {}
    end

    def run
      # TODO: run by multi thread @inputs
      @inputs.first.run do |event|
        event = @filters.reduce(event) { |e, f| f.filter(e) if e }

        next unless event

        event = @parsers.reduce(event) { |_e, p| p.parse(event) if p }

        next unless event

        @event_buffer << event
        vector = @event_buffer.generate_vector

        next unless vector

        @vector_buffer << vector
        command_executor = @vector_buffer.generate_command_executor
        command_executor.execute if command_executor.executable?
      end
    end
  end
end
