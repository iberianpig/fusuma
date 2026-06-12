# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/libinput/constants"

module Fusuma
  module Libinput
    RSpec.describe Constants do
      describe "EVENT_TYPE_MAP" do
        it "maps all gesture event types" do
          expect(Constants::EVENT_TYPE_MAP.keys).to contain_exactly(
            800, 801, 802, 803, 804, 805, 806, 807
          )
        end

        it "maps swipe events correctly" do
          expect(Constants::EVENT_TYPE_MAP[800]).to eq(["swipe", "begin"])
          expect(Constants::EVENT_TYPE_MAP[801]).to eq(["swipe", "update"])
          expect(Constants::EVENT_TYPE_MAP[802]).to eq(["swipe", "end"])
        end

        it "maps pinch events correctly" do
          expect(Constants::EVENT_TYPE_MAP[803]).to eq(["pinch", "begin"])
          expect(Constants::EVENT_TYPE_MAP[804]).to eq(["pinch", "update"])
          expect(Constants::EVENT_TYPE_MAP[805]).to eq(["pinch", "end"])
        end

        it "maps hold events correctly" do
          expect(Constants::EVENT_TYPE_MAP[806]).to eq(["hold", "begin"])
          expect(Constants::EVENT_TYPE_MAP[807]).to eq(["hold", "end"])
        end
      end

      describe "GESTURE_EVENT_TYPE_RANGE" do
        it "covers all gesture event type values" do
          expect(Constants::GESTURE_EVENT_TYPE_RANGE).to eq(800..807)
          (800..807).each do |type|
            expect(Constants::GESTURE_EVENT_TYPE_RANGE).to cover(type)
          end
        end

        it "does not cover non-gesture events" do
          expect(Constants::GESTURE_EVENT_TYPE_RANGE).not_to cover(1)
          expect(Constants::GESTURE_EVENT_TYPE_RANGE).not_to cover(799)
          expect(Constants::GESTURE_EVENT_TYPE_RANGE).not_to cover(808)
        end
      end

      describe "CAPABILITY_MAP" do
        it "maps capability constants to names" do
          expect(Constants::CAPABILITY_MAP[Constants::DEVICE_CAP_GESTURE]).to eq("gesture")
          expect(Constants::CAPABILITY_MAP[Constants::DEVICE_CAP_POINTER]).to eq("pointer")
        end
      end

      describe "DEVICE_EVENT_TYPES" do
        it "contains device added and removed" do
          expect(Constants::DEVICE_EVENT_TYPES).to contain_exactly(1, 2)
        end
      end

      describe "device capabilities" do
        it "defines DEVICE_CAP_GESTURE as 5" do
          expect(Constants::DEVICE_CAP_GESTURE).to eq(5)
        end
      end
    end
  end
end
