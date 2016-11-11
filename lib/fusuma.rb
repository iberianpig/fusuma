require_relative 'fusuma/version'
require_relative 'fusuma/action_stack'
require_relative 'fusuma/gesture_action'
require 'logger'
require 'open3'
require 'yaml'

# this is top level module
module Fusuma
  class << self
    def run
      read_libinput
    end

    private
    @@trigger_timeout = Time.new

    def read_libinput
      Open3.popen3(libinput_command) do |_i, o, _e, _w|
        o.each do |line|
          gesture_action = GestureAction.initialize_by_libinput(line, device_name)
          next if gesture_action.nil?
          @action_stack ||= ActionStack.new
          @action_stack.push gesture_action unless Time.new < @@trigger_timeout
          gesture_info = @action_stack.gesture_info
          trigger_keyevent(gesture_info) unless gesture_info.nil?
        end
      end
    end

    def libinput_command
      @libinput_command ||= "stdbuf -oL -- libinput-debug-events --device \
    /dev/input/#{device_name}"
    end

    def device_name
      return @device_name unless @device_name.nil?
      Open3.popen3('libinput-list-devices') do |_i, o, _e, _w|
        o.each do |line|
          extracted_input_device_from(line)
          next unless touch_is_available?(line)
          return @device_name
        end
      end
    end

    def extracted_input_device_from(line)
      return unless line =~ /^Kernel: /
      @device_name = line.match(/event[0-9]+/).to_s
    end

    def touch_is_available?(line)
      return false unless line =~ /^Tap-to-click: /
      return false if line =~ %r{n/a}
      true
    end

    def trigger_keyevent(gesture_info)
      case gesture_info.action
      when 'swipe'
        swipe(gesture_info.finger, gesture_info.direction.move)
        @@trigger_timeout = Time.new + 0.5
      when 'pinch'
        pinch(gesture_info.direction.pinch)
        @@trigger_timeout = Time.new + 0.05
      end
    end

    def swipe(finger, direction)
      shortcut = event_map['swipe'][finger.to_i][direction]['shortcut']
      `xdotool key #{shortcut}`
    end

    def pinch(zoom)
      shortcut = event_map['pinch'][zoom]['shortcut']
      `xdotool key #{shortcut}`
    end

    def event_map
      @event_map ||= YAML.load_file(config_file)
    end

    def config_file
      filename = 'fusuma/config.yml'
      original_path = File.expand_path "~/.config/#{filename}"
      default_path = File.expand_path "../#{filename}", __FILE__
      File.exist?(original_path) ? original_path : default_path
    end
  end
end
