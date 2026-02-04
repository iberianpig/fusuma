# frozen_string_literal: true

require "open3"
require_relative "input"

module Fusuma
  module Plugin
    module Inputs
      # Monitors custom commands and outputs their results as context events
      class WatchContextInput < Input
        include Singleton

        # Returns the reader end of IO.pipe
        #: () -> StringIO
        def io
          @io ||= begin
            reader, writer = create_io
            start(reader, writer)
            reader
          end
        end

        #: (StringIO, StringIO) -> void
        def start(reader, writer)
          Thread.new do
            watch_loop(writer)
          end
        end

        # Executes a command and returns the result
        # Returns nil on failure
        #: (String) -> String?
        def execute_command(command)
          stdout, stderr, status = Open3.capture3(command)
          unless status.success?
            MultiLogger.warn "watch_context command failed: #{command} (exit status: #{status.exitstatus})"
            MultiLogger.warn "  stderr: #{stderr}" unless stderr.empty?
            return nil
          end

          stdout.strip
        end

        # Reads the plugin config from: plugin: inputs: watch_context_input:
        # Returns an empty Hash if no config is found
        #: () -> Hash[untyped, untyped]
        def watch_contexts
          result = Config.search(config_index)
          result.is_a?(Hash) ? result : {}
        end

        # Executes the specified command periodically and
        # writes to writer in "name:value" format only when the value changes
        #: (name: Symbol | String, command: String, writer: StringIO) -> void
        def watch_command(name:, command:, writer:)
          value = execute_command(command)
          return if value.nil?

          @last_values ||= {}
          return if @last_values[name] == value

          @last_values[name] = value
          writer.puts "#{name}:#{value}"
        end

        #: () -> Hash[untyped, untyped]
        def reset_last_values
          @last_values = {}
        end

        private

        DEFAULT_INTERVAL = 1.0

        def create_io
          IO.pipe
        end

        #: (StringIO) -> void
        def watch_loop(writer)
          loop do
            contexts = watch_contexts
            if contexts.empty?
              sleep DEFAULT_INTERVAL
              next
            end

            contexts.each do |name, config|
              command = config[:command]
              next if command.nil?

              watch_command(name: name, command: command, writer: writer)
            end

            interval = find_min_interval(contexts)
            sleep interval
          end
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e
        end

        #: (Hash[untyped, untyped]) -> Float
        def find_min_interval(contexts)
          intervals = contexts.values.filter_map { |c| c[:interval] }
          intervals.empty? ? DEFAULT_INTERVAL : intervals.min
        end
      end
    end
  end
end
