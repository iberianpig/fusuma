# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "./lib/fusuma/libinput/interface"

module Fusuma
  module Libinput
    RSpec.describe Interface do
      subject(:interface) { described_class.new }

      describe "#to_ptr" do
        it "returns a non-null Fiddle::Pointer" do
          expect(interface.to_ptr).to be_a(Fiddle::Pointer)
          expect(interface.to_ptr.null?).to be false
        end

        it "has size for two function pointers" do
          expect(interface.to_ptr.size).to eq(Fiddle::SIZEOF_VOIDP * 2)
        end
      end

      describe "open_restricted callback" do
        it "opens a file and returns fd" do
          tmpfile = Tempfile.new("libinput_test")
          path = tmpfile.path
          tmpfile.close

          # Extract the open_restricted closure
          open_cb = interface.instance_variable_get(:@open_restricted)
          fd = open_cb.call(path, File::RDONLY, Fiddle::NULL)
          expect(fd).to be >= 0

          IO.for_fd(fd, autoclose: true).close
          tmpfile.unlink
        end

        it "returns negative errno for nonexistent path" do
          open_cb = interface.instance_variable_get(:@open_restricted)
          result = open_cb.call("/nonexistent/path/device", File::RDONLY, Fiddle::NULL)
          expect(result).to be < 0
        end
      end

      describe "close_restricted callback" do
        it "closes the given fd without error" do
          tmpfile = Tempfile.new("libinput_test")
          fd = IO.sysopen(tmpfile.path, File::RDONLY)

          close_cb = interface.instance_variable_get(:@close_restricted)
          expect { close_cb.call(fd, Fiddle::NULL) }.not_to raise_error

          tmpfile.close
          tmpfile.unlink
        end
      end
    end
  end
end
