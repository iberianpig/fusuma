# frozen_string_literal: true

require_relative '../formats/records/record.rb'

module Fusuma
  module Plugin
    module Parsers
      # parse libinput and generate vector
      class LibinputGestureParser < Parser
        DEFAULT_SOURCE = 'libinput_command_input'

        # @param record [String]
        # @return [Records::GestureRecord, nil]
        def parse_record(record)
          case line = record.to_s
          when /GESTURE_SWIPE|GESTURE_PINCH/
            gesture, status, finger, direction = parse_libinput(line)
          else
            return
          end

          Formats::Records::GestureRecord.new(status: status,
                                              gesture: gesture,
                                              finger: finger,
                                              direction: direction)
        end

        private

        def parse_libinput(line)
          _device, event_name, _time, other = line.strip.split(nil, 4)
          finger, other = other.split(nil, 2)
          direction = parse_direction(other)
          [*detect_gesture(event_name), finger, direction]
        end

        def detect_gesture(event_name)
          event_name =~ /GESTURE_(SWIPE|PINCH)_(BEGIN|UPDATE|END)/
          [Regexp.last_match(1).downcase, Regexp.last_match(2).downcase]
        end

        def parse_direction(line)
          return if line.nil?

          move_x, move_y, _, _, _, zoom, _, rotate = line.tr('/|(|)', ' ').split
          Formats::Records::GestureRecord::Direction.new(move_x.to_f, move_y.to_f,
                                                         zoom.to_f, rotate.to_f)
        end
      end
    end
  end
end
