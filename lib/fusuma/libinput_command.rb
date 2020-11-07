# frozen_string_literal: true

require 'posix/spawn'

module Fusuma
  # Execute libinput command
  class LibinputCommand
    def initialize(libinput_options: [], commands: {})
      @debug_events_command = commands[:debug_events_command]
      @list_devices_command = commands[:list_devices_command]
      @libinput_options = libinput_options
    end

    # `libinput-list-devices` and `libinput-debug-events` are deprecated,
    # use `libinput list-devices` and `libinput debug-events` from 1.8.
    NEW_CLI_OPTION_VERSION = 1.8

    DEFAULT_WAIT_TIME = 0.3
    TIMEOUT_MESSAGE = 'LIBINPUT TIMEOUT'

    # @return [Boolean]
    def new_cli_option_available?
      Gem::Version.new(version) >= Gem::Version.new(NEW_CLI_OPTION_VERSION)
    end

    # @return [String]
    def version
      # versiom_command prints "1.6.3\n"
      @version ||= `#{version_command}`.strip
    end

    # @yieldparam [String] gives a line in libinput list-devices output to the block
    def list_devices
      cmd = list_devices_command
      MultiLogger.debug(list_devices: cmd)
      p, i, o, e = POSIX::Spawn.popen4(cmd)
      i.close
      o.each { |line| yield(line) }
    ensure
      [i, o, e].each { |io| io.close unless io.closed? }
      Process.waitpid(p)
    end

    # @return [String] return a latest line libinput debug-events
    def debug_events
      @debug_events ||= begin
                          _p, i, o, _e = POSIX::Spawn.popen4(debug_events_with_options)
                          i.close
                          o
                        end
    end

    # @return [String] command
    # @raise [SystemExit]
    def version_command
      if @debug_events_command && @list_devices_command
        "#{@list_devices_command} --version"
      elsif which('libinput')
        'libinput --version'
      elsif which('libinput-list-devices')
        'libinput-list-devices --version'
      else
        MultiLogger.error 'install libinput-tools'
        exit 1
      end
    end

    def list_devices_command
      if @list_devices_command
        @list_devices_command
      elsif new_cli_option_available?
        'libinput list-devices'
      else
        'libinput-list-devices'
      end
    end

    def debug_events_command
      if @debug_events_command
        @debug_events_command
      elsif new_cli_option_available?
        'libinput debug-events'
      else
        'libinput-debug-events'
      end
    end

    def debug_events_with_options
      prefix = 'stdbuf -oL --'
      "#{prefix} #{debug_events_command} #{@libinput_options.join(' ')}".strip
    end

    private

    def wait_time
      DEFAULT_WAIT_TIME
    end

    # which in ruby: Checking if program exists in $PATH from ruby
    # (https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby)
    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    # @return [String, nil]
    def which(command)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{command}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end
  end
end
