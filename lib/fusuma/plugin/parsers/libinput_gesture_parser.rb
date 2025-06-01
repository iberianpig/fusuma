# frozen_string_literal: true

require_relative "../events/records/record"
require_relative "../events/records/gesture_record"
require_relative "../../libinput_command"

module Fusuma
  module Plugin
    module Parsers
      # parse libinput and generate gesture record
      class LibinputGestureParser < Parser
        DEFAULT_SOURCE = "libinput_command_input"

        # @param record [String]
        # @return [Records::GestureRecord, nil]
        #: (Fusuma::Plugin::Events::Records::TextRecord) -> Fusuma::Plugin::Events::Records::GestureRecord
        def parse_record(record)
          case line = record.to_s
          when /GESTURE_SWIPE|GESTURE_PINCH|GESTURE_HOLD/
            gesture, status, finger, delta = parse_libinput(line)
          else
            return
          end

          Events::Records::GestureRecord.new(status: status,
            gesture: gesture,
            finger: finger,
            delta: delta)
        end

        private

        #: (String) -> Array[untyped]
        def parse_libinput(line)
          if libinput_1_27_0_or_later?
            parse_line_1_27_0_or_later(line)
          else
            parse_line(line)
          end
        end

        #: () -> bool
        def libinput_1_27_0_or_later?
          return @libinput_1_27_0_or_later if defined?(@libinput_1_27_0_or_later)

          @libinput_1_27_0_or_later = Inputs::LibinputCommandInput.new.command.libinput_1_27_0_or_later?
        end

        #: (String) -> Array[untyped]
        def parse_line(line)
          _device, event_name, _time, other = line.strip.split(nil, 4)
          finger, other = other.split(nil, 2)

          gesture, status = *detect_gesture(event_name)

          status = "cancelled" if gesture == "hold" && status == "end" && other == "cancelled"
          delta = parse_delta(other)
          [gesture, status, finger, delta]
        end

        #: (String) -> Array[untyped]
        def parse_line_1_27_0_or_later(line)
          _device, event_name, other = line.strip.split(nil, 3)

          if other[0] != "+"
            _seq, other = other.split(nil, 2)
          end

          _time, finger, other = other.split(nil, 3)

          gesture, status = *detect_gesture(event_name)

          status = "cancelled" if gesture == "hold" && status == "end" && other == "cancelled"
          delta = parse_delta(other)
          [gesture, status, finger, delta]
        end

        #: (String) -> Array[untyped]
        def detect_gesture(event_name)
          event_name =~ /GESTURE_(SWIPE|PINCH|HOLD)_(BEGIN|UPDATE|END)/
          gesture = Regexp.last_match(1).downcase
          status = Regexp.last_match(2).downcase
          [gesture, status]
        end

        #: (String?) -> Fusuma::Plugin::Events::Records::GestureRecord::Delta?
        def parse_delta(line)
          return if line.nil?

          move_x, move_y, unaccelerated_x, unaccelerated_y, _, zoom, _, rotate =
            line.tr("/|(|)", " ").split
          Events::Records::GestureRecord::Delta.new(move_x.to_f, move_y.to_f,
            unaccelerated_x.to_f, unaccelerated_y.to_f,
            zoom.to_f, rotate.to_f)
        end
      end
    end
  end
end
