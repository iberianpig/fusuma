require_relative 'fusuma/version'
require_relative 'fusuma/event_buffer'
require_relative 'fusuma/vector_buffer'
require_relative 'fusuma/multi_logger'
require_relative 'fusuma/config.rb'
require_relative 'fusuma/device.rb'
require_relative 'fusuma/plugin/input.rb'
require_relative 'fusuma/plugin/filter.rb'
require_relative 'fusuma/plugin/parser.rb'

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
        print_device_list if option[:list]
        reload_custom_config(option[:config_path])
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

      def available_plugins
        MultiLogger.info 'Available Plugins: '
        Plugin::Manager.plugins.each do |base, plugins|
          plugins.each { |plugin| MultiLogger.info "  #{plugin} < #{base}" }
        end
        MultiLogger.info '---------------------------------------------'
      end

      def print_device_list
        puts Device.names
        exit(0)
      end

      def reload_custom_config(config_path = nil)
        return unless config_path

        MultiLogger.info "use custom path: #{config_path}"
        Config.instance.custom_path = config_path
        Config.reload
      end

      def debug_mode
        print_version
        available_plugins
        MultiLogger.instance.debug_mode = true
      end
    end

    def initialize
      @input = Plugin::Inputs::Generator.new.generate
      @filter = Plugin::Filters::Generator.new.generate
      @parser = Plugin::Parsers::Generator.new.generate
      @event_buffer = EventBuffer.new
      @vector_buffer = VectorBuffer.new
    end

    def run
      @input.run do |event|
        event = @filter.filter(event)

        next unless event

        event = @parser.parse(event)

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
