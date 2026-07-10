# frozen_string_literal: true

require "logger"
require "singleton"

# module as namespace
module Fusuma
  # logger separate between stdout and strerr
  class MultiLogger < Logger
    include Singleton

    DEFAULT_IGNORE_PATTERN = /timer_input/ #: Regexp

    attr_reader :err_logger
    attr_accessor :debug_mode
    attr_accessor :ignore_pattern #: Regexp

    class << self
      attr_writer :filepath

      #: (untyped) -> void
      def info(msg)
        instance.info(msg)
      end

      #: (untyped) -> void
      def debug(msg)
        instance.debug(msg)
      end

      #: (untyped) -> void
      def warn(msg)
        instance.warn(msg)
      end

      #: (untyped) -> void
      def error(msg)
        instance.error(msg)
      end
    end

    #: () -> void
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
      @ignore_pattern = DEFAULT_IGNORE_PATTERN
    end

    #: (untyped) -> void
    def debug(msg)
      return unless debug_mode?

      return if ignore_pattern?(msg)

      super
    end

    #: (untyped) -> void
    def warn(msg)
      err_logger.warn(msg)
    end

    #: (untyped) -> void
    def error(msg)
      err_logger.error(msg)
    end

    #: () -> bool
    def debug_mode?
      debug_mode
    end

    private

    #: (untyped) -> bool
    def ignore_pattern?(msg)
      case msg
      when Hash
        e = msg.values.find { |v| v.is_a? Fusuma::Plugin::Events::Event }
        return false unless e

        e.tag.match?(@ignore_pattern)
      when String
        msg.match?(@ignore_pattern)
      else
        false
      end
    end
  end
end
