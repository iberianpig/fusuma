#!/usr/bin/env ruby

require 'pry-byebug'
require 'logger'
require 'open3'

# manage actions
class ActionStack < Array
  def initialize(*args)
    super(*args)
    @logger = Logger.new(STDOUT)
  end

  # return { finger:, direction:, action: } or nil
  def gesture_info
    return unless enough_actions?
    direction = detect_direction
    finger = detect_finger
    action = detect_action
    clear
    @logger.debug "-------#{finger}--#{direction}--#{action}------"
    { finger: finger, direction: direction, action: action }
  end

  def <<(gesture_action)
    super(gesture_action)
    clear if action_end?
  end

  private

  def detect_direction
    direction_hash = sum_direction
    x = direction_hash[:x]
    y = direction_hash[:y]
    if x.abs > y.abs
      return 'right' if x > 0
      return 'left'
    else
      return 'down' if y > 0
      return 'up'
    end
  end

  def detect_finger
    first.finger
  end

  def sum_direction
    directions_arr = map(&:directions).compact.map do |directions|
      x, y = directions.split('/')
      { x: x.to_f, y: y.to_f }
    end
    directions_arr.inject(x: 0, y: 0) do |sum, directions|
      sum[:x] += directions[:x]
      sum[:y] += directions[:y]
      { x: sum[:x], y: sum[:y] }
    end
  end

  def action_end?
    last_action_name =~ /_END$/
  end

  def last_action_name
    return false if last.class != GestureAction
    last.action_name
  end

  def enough_actions?
    length > 7 # TODO: should be detected by distance per time
  end

  def detect_action
    first.action_name =~ /GESTURE_(.*?)_/
    Regexp.last_match(1).downcase
  end
end

# pinch or swipe action
class GestureAction
  def initialize(action_name, finger, directions, time)
    @action_name = action_name
    @finger = finger
    @directions = directions
    @time = time
  end
  attr_reader :action_name, :finger, :directions, :time
end

# Main class
class Fusuma
  def run
    @logger = Logger.new(STDOUT)
    read_libinput
  end

  private

  def device_name
    return @device_name unless @device_name.nil?
    Open3.popen3('libinput-list-devices') do |_i, o, _e, _w|
      o.each do |line|
        @device_name = line.match(/event[0-9]/).to_s if line =~ /^Kernel: /
        next unless line =~ /^Tap-to-click: /
        return @device_name unless line =~ %r{n/a}
      end
    end
  end

  def libinput_command
    @libinput_command ||= "stdbuf -oL -- libinput-debug-events --device \
    /dev/input/#{device_name}"
  end

  def read_libinput
    Open3.popen3(libinput_command) do |_i, o, _e, _w|
      o.each do |line|
        gesture_action = generate_gesture_action(line)
        next if gesture_action.nil?
        @action_stack ||= ActionStack.new
        @action_stack << gesture_action
        gesture_info = @action_stack.gesture_info
        trigger_keyevent(gesture_info) unless gesture_info.nil?
      end
    end
  end

  def generate_gesture_action(line)
    return unless line.to_s =~ /^#{device_name}/
    rows = line.split("\t").map(&:strip)
    action = rows[1].split[0]
    time = rows[1].split[1]
    finger_and_directions = rows[2].split
    finger_num = finger_and_directions[0]
    directions = (finger_and_directions[1] if finger_and_directions.length > 2)

    return unless action =~ /GESTURE_SWIPE/

    GestureAction.new(action, finger_num, directions, time)
  end

  def trigger_keyevent(gesture_info)
    action    = gesture_info[:action]
    finger    = gesture_info[:finger]
    direction = gesture_info[:direction]
    case action
    when 'swipe'
      swipe(finger, direction)
    when 'pinch'
      pinch
    end
  end

  def swipe(finger, direction)
    shortcut = event_map[:swipe][finger][direction.to_sym][:shortcut]
    `xdotool key #{shortcut}`
  end

  def pinch(zoom)
    shortcut = event_map[:pinch][zoom.to_sym][:shortcut]
    `xdotool key #{shortcut}`
  end

  def event_map
    {
      swipe: {
        '3' => {
          left: { shortcut: 'alt+Right' },
          right: { shortcut: 'alt+Left' },
          up: { shortcut: 'ctrl+t' },
          down: { shortcut: 'ctrl+w' }
        },
        '4' => {
          left: { shortcut: 'super+Right' },
          right: { shortcut: 'super+Left' },
          up: { shortcut: 'super+a' },
          down: { shortcut: 'super+s' }
        }
      },
      pinch: {
        in: { shortcut: 'ctrl+minus' },
        out: { shortcut: 'ctrl+plus' }
      }
    }
  end

  Fusuma.new.run if __FILE__ == $PROGRAM_NAME
end
