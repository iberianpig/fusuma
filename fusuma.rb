#!/usr/bin/env ruby

require 'pry-byebug'
require 'logger'
require 'open3'

# TODO: Read .yml file and set custom shortcut keys
# TODO: Write gemspec
# TODO: Write test
# TODO: Write README.md
# TODO: Support long-press
# TODO: Actions' thresholds should be detected by move per time
# TODO: Add custom parameters for threshold of swipe or pinch actions

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
    finger    = detect_finger
    action    = detect_action
    clear
    { finger: finger, direction: direction, action: action }
  end

  def <<(gesture_action)
    super(gesture_action)
    clear if action_end?
  end

  private

  def detect_direction
    direction_hash = sum_direction
    move = detect_move(direction_hash)
    pinch = detect_pinch(direction_hash)
    { move: move, pinch: pinch }
  end

  def detect_move(direction_hash)
    if direction_hash[:move][:x].abs > direction_hash[:move][:y].abs
      return direction_hash[:move][:x] > 0 ? 'right' : 'left'
    end
    direction_hash[:move][:y] > 0 ? 'down' : 'up'
  end

  def detect_pinch(direction_hash)
    direction_hash[:pinch] > 1 ? 'in' : 'out'
  end

  def detect_finger
    last.finger
  end

  def sum_direction
    move_x = sum_attrs(:move_x)
    move_y = sum_attrs(:move_y)
    pinch  = mul_attrs(:pinch)
    { move: { x: move_x, y: move_y }, pinch: pinch }
  end

  def sum_attrs(attr)
    send('map') do |gesture_action|
      gesture_action.send(attr.to_sym.to_s)
    end.compact.inject(:+)
  end

  def mul_attrs(attr)
    send('map') do |gesture_action|
      num = gesture_action.send(attr.to_sym.to_s)
      # NOTE: ignore 0.0, treat as 1(immutable)
      num.zero? ? 1 : num
    end.compact.inject(:*)
  end

  def action_end?
    last_action_name =~ /_END$/
  end

  def last_action_name
    return false if last.class != GestureAction
    last.action
  end

  def enough_actions?
    length > 7 # TODO: should be detected by move per time
  end

  def detect_action
    first.action =~ /GESTURE_(.*?)_/
    Regexp.last_match(1).downcase
  end
end

# pinch or swipe action
class GestureAction
  def initialize(time, action, finger, directions)
    @time   = time
    @action = action
    @finger = finger
    @move_x = directions[:move][:x].to_f
    @move_y = directions[:move][:y].to_f
    @pinch  = directions[:pinch].to_f
  end
  attr_reader :time, :action, :finger,
              :move_x, :move_y, :pinch

  class << self
    def initialize_by_libinput(line, device_name)
      @logger ||= Logger.new(STDOUT)
      return unless line.to_s =~ /^#{device_name}/
      return if line.to_s =~ /_BEGIN/
      return unless line.to_s =~ /GESTURE_SWIPE|GESTURE_PINCH/
      time, action, finger_num, directions = parse_from_libinput(line)
      @logger.debug(line)
      @logger.debug(directions)
      GestureAction.new(time, action, finger_num, directions)
    end

    private

    def parse_from_libinput(line)
      _device, action_time, finger_directions = line.split("\t").map(&:strip)
      action, time = action_time.split
      finger_num, move_x, move_y, _, _, _, pinch = finger_directions.tr('/', ' ').split
      directions = { move: { x: move_x, y: move_y }, pinch: pinch }
      [time, action, finger_num, directions]
    end
  end
    
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
        gesture_action = GestureAction.initialize_by_libinput(line, device_name)
        next if gesture_action.nil?
        @action_stack ||= ActionStack.new
        @action_stack << gesture_action
        gesture_info = @action_stack.gesture_info
        trigger_keyevent(gesture_info) unless gesture_info.nil?
      end
    end
  end

  def trigger_keyevent(gesture_info)
    action    = gesture_info[:action]
    finger    = gesture_info[:finger]
    direction = gesture_info[:direction]
    case action
    when 'swipe'
      @logger.debug('swipe')
      swipe(finger, direction[:move])
    when 'pinch'
      pinch(direction[:pinch])
      @logger.debug('pinch')
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
          left:  { shortcut: 'alt+Right' },
          right: { shortcut: 'alt+Left' },
          up:    { shortcut: 'ctrl+t' },
          down:  { shortcut: 'ctrl+w' }
        },
        '4' => {
          left:  { shortcut: 'super+Right' },
          right: { shortcut: 'super+Left' },
          up:    { shortcut: 'super+a' },
          down:  { shortcut: 'super+s' }
        }
      },
      pinch: {
        in:  { shortcut: 'ctrl+plus' },
        out: { shortcut: 'ctrl+minus' }
      }
    }
  end

  Fusuma.new.run if __FILE__ == $PROGRAM_NAME
end
