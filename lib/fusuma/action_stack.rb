module Fusuma
  # manage actions
  class ActionStack < Array
    ELAPSED_TIME = 0.01

    def initialize(*args)
      super(*args)
    end

    def generate_event_trigger
      return unless enough_actions?
      action_type = detect_action_type
      direction = detect_direction(action_type)
      return if direction.nil?
      @last_triggered_time = last.time
      finger = detect_finger
      clear
      EventTrigger.new(finger, direction, action_type)
    end

    def push(gesture_action)
      super(gesture_action)
      clear if action_end?
    end
    alias << push

    private

    def detect_direction(action_type)
      vector = generate_vector(action_type)
      return if vector && !vector.enough?
      vector.direction
    end

    def generate_vector(action_type)
      case action_type
      when 'swipe'
        sum_swipe
      when 'pinch'
        sum_swipe
      end
    end

    def detect_finger
      last.finger
    end

    def sum_swipe
      move_x = sum_attrs(:move_x)
      move_y = sum_attrs(:move_y)
      Swipe.new(move_x, move_y)
    end

    def sum_pinch
      move_x = sum_attrs(:move_x)
      move_y = sum_attrs(:move_y)
      diameter = sum_attrs(:zoom)
      delta_diameter = diameter - first.zoom
      Pinch.new(move_x, move_y, delta_diameter)
    end

    def avg_swipe
      move_x = avg_attrs(:move_x)
      move_y = avg_attrs(:move_y)
      Swipe.new(move_x, move_y)
    end

    def avg_pinch
      move_x = avg_attrs(:move_x)
      move_y = avg_attrs(:move_y)
      diameter = avg_attrs(:zoom)
      delta_diameter = diameter - first.zoom
      Pinch.new(move_x, move_y, delta_diameter)
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
      length >= if Config.misc('actioncount') != false then Config.misc('actioncount') else 2 end
    end

    def enough_elapsed_time?
      return false if length.zero?
      (last.time - first.time) > ELAPSED_TIME
    end

    def last_triggered_time
      @last_triggered_time ||= 0
    end

    def detect_action_type
      first.action =~ /GESTURE_(.*?)_/
      Regexp.last_match(1).downcase
    end
  end
end
