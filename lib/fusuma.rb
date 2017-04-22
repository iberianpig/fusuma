require_relative 'fusuma/version'
require_relative 'fusuma/action_stack'
require_relative 'fusuma/gesture_action'
require_relative 'fusuma/gesture_info'
require_relative 'fusuma/swipe.rb'
require_relative 'fusuma/pinch.rb'
require_relative 'fusuma/multi_logger'
require_relative 'fusuma/config.rb'
require 'logger'
require 'open3'
require 'yaml'

# this is top level module
module Fusuma
  # main class
  class Runner
    class << self
      def run(option = {})
        read_options(option)
        instance = new
        instance.read_libinput
      end

      def read_options(option)
        config_path = option.fetch(:config, nil)
        if config_path
          Config.instance.custom_path = config_path
          Config.reload
        end
        debug = option.fetch(:verbose, nil)
        MultiLogger.instance.debug_mode = true if debug
      end
    end

    def read_libinput
      Open3.popen3(libinput_command) do |_i, o, _e, _w|
        o.each do |line|
          gesture_action = GestureAction.initialize_by(line, device_names)
          next if gesture_action.nil?
          @action_stack ||= ActionStack.new
          @action_stack.push gesture_action
          gesture_info = @action_stack.gesture_info
          gesture_info.trigger_keyevent unless gesture_info.nil?
        end
      end
    end

    def device_names
      return @device_names unless @device_names.nil?
      names = []
      @device_names = list_devices_logs.map do |line|
        MultiLogger.debug(line)
        name = extracted_input_device_from(line)
        names << name unless name.nil?
        next unless natural_scroll_is_available?(line)
        names.pop
      end.compact
    end

    private

    def list_devices_logs
      Open3.popen3('libinput-list-devices') do |_i, o, _e, _w|
        return o.to_a
      end
    end

    def libinput_command
      return @libinput_command if @libinput_command
      # NOTE: --enable-dwt means "disable while typing"
      prefix = 'stdbuf -oL --'
      command = 'libinput-debug-events --enable-dwt'
      device_option = if device_names.size == 1
                        "--device /dev/input/#{device_names.first}"
                      end
      @libinput_command = [prefix, command, device_option].join(' ')
      MultiLogger.debug(libinput_command: @libinput_command)
      @libinput_command
    end

    def extracted_input_device_from(line)
      return unless line =~ /^Kernel: /
      line.match(/event[0-9]+/).to_s
    end

    def natural_scroll_is_available?(line)
      return false unless line =~ /^Nat.scrolling: /
      return false if line =~ %r{n/a}
      true
    end
  end
end
