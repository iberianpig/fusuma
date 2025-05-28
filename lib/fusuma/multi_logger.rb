# frozen_string_literal: true

# module as namespace
module Fusuma
  require "logger"
  require "singleton"
  # logger separate between stdout and strerr
  class MultiLogger < Logger
    include Singleton

    attr_reader :err_logger
    attr_accessor :debug_mode

    class << self
      attr_writer :filepath

      def info(msg)
        instance.info(msg)
      end

      def debug(msg)
        instance.debug(msg)
      end

      def warn(msg)
        instance.warn(msg)
      end

      def error(msg)
        instance.error(msg)
      end
    end

    def initialize
      filepath = self.class.instance_variable_get(:@filepath)
      if filepath
        logfile = File.new(filepath, "a")
        logfile.sync = true
        super(logfile)
        $stderr = logfile
      else
        super($stdout)
      end
      @err_logger = Logger.new($stderr)
      @debug_mode = false
    end

    def debug(msg)
      return unless debug_mode?

      return if ignore_pattern?(msg)

      super
    end

    def warn(msg)
      err_logger.warn(msg)
    end

    def error(msg)
      err_logger.error(msg)
    end

    def debug_mode?
      debug_mode
    end

    private

    def ignore_pattern?(msg)
      # TODO: configurable from config.yml
      # pattern = /timer_input|remap_touchpad_input|thumbsense context|libinput_command_input/
      pattern = /timer_input/
      case msg
      when Hash
        e = msg.values.find { |v| v.is_a? Fusuma::Plugin::Events::Event }
        return unless e

        e.tag.match?(pattern)
      when String
        msg.match?(pattern)
      else
        false
      end
    end
  end
end
