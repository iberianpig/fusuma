# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/string_support"

RSpec.describe String do
  describe "#camelize" do
    it "converts snake_case to CamelCase" do
      expect("gesture_buffer".camelize).to eq "GestureBuffer"
    end

    it "capitalizes a single word" do
      expect("swipe".camelize).to eq "Swipe"
    end
  end

  describe "#underscore" do
    it "converts a namespaced class name to a path" do
      expect("Fusuma::Plugin::Buffers::GestureBuffer".underscore)
        .to eq "fusuma/plugin/buffers/gesture_buffer"
    end

    it "separates consecutive uppercase letters followed by a word" do
      expect("APIClient".underscore).to eq "api_client"
    end

    it "converts hyphens to underscores" do
      expect("foo-bar".underscore).to eq "foo_bar"
    end
  end
end
