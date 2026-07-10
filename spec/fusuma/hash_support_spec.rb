# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/hash_support"

RSpec.describe Hash do
  describe "#deep_merge" do
    it "merges nested hashes recursively" do
      receiver = {a: {b: 1, c: 2}, d: 3}
      other = {a: {c: 20, e: 30}, f: 4}

      expect(receiver.deep_merge(other)).to eq(a: {b: 1, c: 20, e: 30}, d: 3, f: 4)
    end

    it "does not modify the receiver" do
      receiver = {a: {b: 1}}
      receiver.deep_merge(a: {b: 2})

      expect(receiver).to eq(a: {b: 1})
    end

    context "with a block" do
      it "resolves conflicted keys with the block" do
        receiver = {a: {b: 1}, c: 10}
        other = {a: {b: 2}, c: 20}

        result = receiver.deep_merge(other) { |_k, this_val, other_val| this_val + other_val }

        expect(result).to eq(a: {b: 3}, c: 30)
      end
    end
  end

  describe "#deep_merge!" do
    it "modifies the receiver" do
      receiver = {a: {b: 1, c: 2}}
      receiver.deep_merge!(a: {c: 20, e: 30})

      expect(receiver).to eq(a: {b: 1, c: 20, e: 30})
    end
  end

  describe "#deep_stringify_keys" do
    it "converts nested keys to strings" do
      hash = {a: {b: {c: 1}}, d: 2}

      expect(hash.deep_stringify_keys).to eq("a" => {"b" => {"c" => 1}}, "d" => 2)
    end
  end

  describe "#deep_symbolize_keys" do
    it "converts nested string keys to symbols" do
      hash = {"a" => {"b" => 1}, "c" => 2}

      expect(hash.deep_symbolize_keys).to eq(a: {b: 1}, c: 2)
    end

    it "keeps keys that do not respond to to_sym" do
      hash = {"a" => 1, 2 => 3}

      expect(hash.deep_symbolize_keys).to eq({:a => 1, 2 => 3})
    end
  end

  describe "#deep_transform_keys" do
    it "transforms nested keys recursively" do
      hash = {a: {b: {c: 1}}}

      result = hash.deep_transform_keys { |key| key.to_s.upcase }

      expect(result).to eq("A" => {"B" => {"C" => 1}})
    end
  end

  describe "#deep_transform_values" do
    it "transforms values in nested hashes" do
      hash = {a: 1, b: {c: 2}}

      expect(hash.deep_transform_values { |v| v * 10 }).to eq(a: 10, b: {c: 20})
    end

    it "transforms values inside arrays" do
      hash = {a: [1, {b: 2}]}

      expect(hash.deep_transform_values { |v| v * 10 }).to eq(a: [10, {b: 20}])
    end
  end
end
