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
        debug = option.fetch(:verbose, false)
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

    private

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

    def device_names
      @device_names ||= Open3.popen3('libinput-list-devices') do |_i, o, _e, _w|
        device_names = []
        o.map do |line|
          MultiLogger.debug(line)
          device_name = extracted_input_device_from(line)
          device_names << device_name unless device_name.nil?
          next unless touch_is_available?(line)
          device_names.pop
        end
      end.compact
    end

    def extracted_input_device_from(line)
      return unless line =~ /^Kernel: /
      line.match(/event[0-9]+/).to_s
    end

    def touch_is_available?(line)
      return false unless line =~ /^Tap-to-click: /
      return false if line =~ %r{n/a}
      true
    end
  end
end
