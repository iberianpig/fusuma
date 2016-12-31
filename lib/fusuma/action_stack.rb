module Fusuma
  # manage actions
  class ActionStack < Array
    def initialize(*args)
      super(*args)
    end

    GestureInfo = Struct.new(:finger, :direction, :action_type)

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
        detect_move
      when 'pinch'
        detect_zoom
      end
    end

    def detect_move
      move = avg_moves
      return unless enough_distance?(move)
      MultiLogger.debug(move: move)
      return move[:x] > 0 ? 'right' : 'left' if move[:x].abs > move[:y].abs
      move[:y] > 0 ? 'down' : 'up'
    end

    def detect_zoom
      diameter = avg_attrs(:zoom)
      return unless enough_diameter?(diameter)
      MultiLogger.debug(diameter: diameter)
      return 'in' if diameter > 1
      'out'
    end

    def detect_finger
      last.finger
    end

    Distance = Struct.new(:x, :y)

    def avg_moves
      move_x = sum_attrs(:move_x) / length
      move_y = sum_attrs(:move_y) / length
      Distance.new(move_x, move_y)
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

    def enough_distance?(move)
      (move[:x].abs > threshold_swipe) || (move[:y].abs > threshold_swipe)
    end

    def enough_diameter?(avg_diameter)
      delta_diameter = if avg_diameter > 1
                         avg_diameter - first.zoom
                       else
                         first.zoom - avg_diameter
                       end
      delta_diameter > threshold_pinch
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

    def config
      @config ||= Config.new
    end

    def threshold_swipe
      base = 20
      @threshold_swipe ||= base * config.threshold('swipe')
    end

    def threshold_pinch
      base = 0.3
      @threshold_pinch ||= base * config.threshold('pinch')
    end
  end
end
