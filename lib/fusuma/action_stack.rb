module Fusuma
  # manage actions
  class ActionStack < Array
    def initialize(*args)
      super(*args)
    end

    def gesture_info
      return unless enough_actions? && enough_time_passed?
      action_type = detect_action_type
      direction = detect_direction(action_type)
      return if direction.nil?
      @last_triggered_time = last.time
      finger = detect_finger
      clear
      GestureInfo.new(finger, direction, action_type)
    end

    def push(gesture_action)
      super(gesture_action)
      clear if action_end?
    end
    alias << push

    private

    def elapsed_time
      return 0 if length.zero?
      last.time - first.time
    end

    def detect_direction(action_type)
      case action_type
      when 'swipe'
        detect_swipe
      when 'pinch'
        detect_pinch
      end
    end

    def detect_swipe
      swipe = avg_swipe
      return unless swipe.enough_distance?
      swipe.direction
    end

    def detect_pinch
      pinch = avg_pinch
      return unless pinch.enough_diameter?
      pinch.direction
    end

    def detect_finger
      last.finger
    end

    def avg_swipe
      move_x = avg_attrs(:move_x)
      move_y = avg_attrs(:move_y)
      Swipe.new(move_x, move_y)
    end

    def avg_pinch
      diameter = avg_attrs(:zoom)
      delta_diameter = diameter - first.zoom
      Pinch.new(delta_diameter)
    end

    def sum_attrs(attr)
      send('map') do |gesture_action|
        gesture_action.send(attr.to_sym.to_s)
      end.compact.inject(:+)
    end

    def avg_attrs(attr)
      sum_attrs(attr) / length
    end

    def action_end?
      last_action_name =~ /_END$/
    end

    def last_action_name
      return false if last.class != GestureAction
      last.action
    end

    def enough_actions?
      (length > 1) && (elapsed_time > 0.05)
    end

    def enough_time_passed?
      (last.time - last_triggerd_time) > 0.5
    end

    def last_triggerd_time
      @last_triggered_time ||= 0
    end

    def detect_action_type
      first.action =~ /GESTURE_(.*?)_/
      Regexp.last_match(1).downcase
    end
  end
end
