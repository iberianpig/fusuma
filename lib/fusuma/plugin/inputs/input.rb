# frozen_string_literal: true

require_relative "../base"
require_relative "../events/event"

module Fusuma
  module Plugin
    module Inputs
      # Inherite this base
      # @abstract Subclass and override {#io} to implement
      class Input < Base
        #: (*nil) -> void
        def initialize(*args)
          super
          @tag = self.class.name.split("Inputs::").last.underscore
        end

        attr_reader :tag

        # Whether this input participates in the input loop. Enabled by
        # default; set `enabled: false` under the plugin in config.yml to
        # skip it (e.g. to turn off libinput_command_input when another
        # input plugin provides events). Plugins may override to opt out
        # by default.
        #
        # Checked on the class BEFORE instantiation: some input plugins
        # have side effects in #initialize (forking subprocesses, grabbing
        # devices), so a disabled input must never be instantiated at all.
        #: () -> bool
        def self.enabled?
          config_enabled != false
        end

        # The `enabled` value configured for this plugin, or nil when not
        # set. Class-level equivalent of config_params(:enabled): the
        # config index is derived from the class name alone.
        #: () -> bool?
        def self.config_enabled
          index = Config::Index.new(name.gsub("Fusuma::", "").underscore.split("/"))
          Config.instance.fetch_config_params(:enabled, index).fetch(:enabled, nil)
        end

        # Wait multiple inputs until it becomes readable
        # @param inputs [Array<Input>]
        # @return [Event]
        #: (Array[untyped]) -> Fusuma::Plugin::Events::Event
        def self.select(inputs)
          ios = IO.select(inputs.map(&:io))
          io = ios&.first&.first

          input = inputs.find { |i| i.io == io }

          input.create_event(record: input.read_from_io)
        end

        # @return [String, Record]
        # IO#readline is blocking method
        # so input plugin must write line to pipe (include `\n`)
        # or, override read_from_io and implement your own read method
        #: () -> String
        def read_from_io
          io.readline(chomp: true)
        rescue EOFError => e
          MultiLogger.error "#{self.class.name}: #{e}"
          MultiLogger.error "Shutdown fusuma process..."
          Process.kill("TERM", Process.pid)
        rescue => e
          MultiLogger.error "#{self.class.name}: #{e}"
          exit 1
        end

        # @return [IO]
        #: () -> nil
        def io
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # @return [Event]
        #: (?record: String) -> Fusuma::Plugin::Events::Event
        def create_event(record: "dummy input")
          e = Events::Event.new(tag: tag, record: record)
          MultiLogger.debug(input_event: e)
          e
        end
      end
    end
  end
end
