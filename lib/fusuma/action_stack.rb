module Fusuma
  # manage actions
  class ActionStack < Array
    def initialize(*args)
      super(*args)
    end

    # return { finger:, direction:, action: } or nil
    def gesture_info
      return unless enough_actions? && enough_time_passed?
      action_type = detect_action_type
      direction = detect_direction(action_type)
      return if direction.nil?
      @last_triggered_time = last.time
      finger = detect_finger
      clear
      MultiLogger.debug(finger: finger, direction: direction,
                        action_type: action_type)
      GestureInfo.new(finger, direction, action_type)
    end

    def push(gesture_action)
      super(gesture_action)
      clear if action_end?
    end
    alias << push

    private

    GestureInfo = Struct.new(:finger, :direction, :action_type)

    def elapsed_time
      return 0 if length == 0
      last.time - first.time
    end

    def detect_direction(action_type)
      case action_type
      when 'swipe'
        detect_move
      when 'pinch'
        detect_zoom
      end
    end

    def detect_move
      moves = sum_moves
      return nil if moves[:x].zero? && moves[:y].zero?
      # MultiLogger.debug(moves: moves)
      return nil if (moves[:x].abs < 200) && (moves[:y].abs < 200)
      if moves[:x].abs > moves[:y].abs
        return moves[:x] > 0 ? 'right' : 'left'
      else
        moves[:y] > 0 ? 'down' : 'up'
      end
    end

    def detect_zoom
      diameter = mul_diameter
      # TODO: change threshold from config files
      if diameter > 10
        'in'
      elsif diameter < 0.1
        'out'
      end
    end

    def detect_finger
      last.finger
    end

    def sum_moves
      move_x = sum_attrs(:move_x)
      move_y = sum_attrs(:move_y)
      { x: move_x, y: move_y }
    end

    def mul_diameter
      mul_attrs(:zoom)
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
      (length > 1) && (elapsed_time > 0.1)
    end

    def enough_time_passed?
      (last.time - last_triggerd_time) > 0.5
    end

    def last_triggerd_time
      @last_triggered_time || 0
    end

    def detect_action_type
      first.action =~ /GESTURE_(.*?)_/
      Regexp.last_match(1).downcase
    end
  end
end
