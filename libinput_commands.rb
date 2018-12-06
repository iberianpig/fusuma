module Fusuma
  # libinput commands wrapper
  class LibinputCommands
    def initialize(*options)
      @options = options
    end

    # `libinput-list-devices` and `libinput-debug-events` are deprecated,
    # use `libinput list-devices` and `libinput debug-events` from 1.8.
    NEW_CLI_OPTION_VERSION = 1.8

    # @return [Boolean]
    def new_cli_option_available?
      Gem::Version.new(version) >= Gem::Version.new(NEW_CLI_OPTION_VERSION)
    end

    # @return [String]
    def version
      # versiom_command prints "1.6.3\n"
      @version ||= `#{version_command}`.strip
    end

    # @yield [line] gives a line in libinput list-devices output to the block
    def list_devices
      cmd = list_devices_command
      MultiLogger.debug(debug_events: cmd)
      Open3.popen3(cmd) do |_i, o, _e, _w|
        o.each { |line| yield(line) }
      end
    end

    # @yield [line] gives a line in libinput debug-events output to the block
    def debug_events
      prefix = 'stdbuf -oL --'
      options = [*@options, device_option]
      cmd = "#{prefix} #{debug_events_command} #{options.join(' ')}".strip
      MultiLogger.debug(debug_events: cmd)
      Open3.popen3(cmd) do |_i, o, _e, _w|
        o.each { |line| yield(line) }
      end
    end

    # @return [String] command
    # @raise [SystemExit]
    def version_command
      if which('libinput')
        'libinput --version'
      elsif which('libinput-list-devices')
        'libinput-list-devices --version'
      else
        MultiLogger.error 'install libinput-tools'
        exit 1
      end
    end

    def list_devices_command
      if new_cli_option_available?
        'libinput list-devices'
      else
        'libinput-list-devices '
      end
    end

    def debug_events_command
      if new_cli_option_available?
        'libinput debug-events --enable-tap'
      else
        'libinput-debug-events --enable-tap'
      end
    end

    private

    # use device option only if libinput detect only 1 device
    # @return [String]
    def device_option
      return unless Device.available.size == 1
      "--device /dev/input/#{Device.available.first.id}"
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
