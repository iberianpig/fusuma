module Fusuma
  # manage actions
  class ActionStack < Array
    def initialize(*args)
      super(*args)
    end

    # return { finger:, direction:, action: } or nil
    def gesture_info
      return unless enough_actions?
      direction = detect_direction
      finger    = detect_finger
      action    = detect_action
      clear
      GestureInfo.new(finger, direction, action)
    end

    def push(gesture_action)
      super(gesture_action)
      clear if action_end?
    end
    alias << push

    private

    GestureInfo = Struct.new(:finger, :direction, :action)
    Direction = Struct.new(:move, :pinch)

    def detect_direction
      direction_hash = sum_direction
      move = detect_move(direction_hash)
      pinch = detect_pinch(direction_hash)
      Direction.new(move, pinch)
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
end
