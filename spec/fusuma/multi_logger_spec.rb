require "spec_helper"
require "tempfile"

module Fusuma
  RSpec.describe MultiLogger do
    let(:message) { "test message" }
    let(:debug_message) { "debug test message" }
    let(:warn_message) { "warn test message" }
    let(:error_message) { "error test message" }
    let(:ignored_message) { "timer_input should be ignored" }
    let(:logfile) { nil }

    before do
      MultiLogger.instance_variable_set(:@singleton__instance__, nil)
      MultiLogger.filepath = logfile
      MultiLogger.instance.debug_mode = false
    end

    describe "#info" do
      it "logs information level messages" do
        expect { MultiLogger.info(message) }.to output.to_stdout_from_any_process
      end
    end

    describe "#debug" do
      context "when debug_mode is false" do
        it "does not log debug messages" do
          expect { MultiLogger.debug(debug_message) }.not_to output.to_stdout_from_any_process
        end
      end

      context "when debug_mode is true" do
        before do
          MultiLogger.instance.debug_mode = true
        end

        it "logs debug messages" do
          expect { MultiLogger.debug(debug_message) }.to output(/#{debug_message}/).to_stdout_from_any_process
        end

        it "does not log debug messages that match the ignore pattern" do
          expect { MultiLogger.debug(ignored_message) }.not_to output(/#{ignored_message}/).to_stdout_from_any_process
        end

        context "when ignore_pattern is customized" do
          before do
            MultiLogger.instance.ignore_pattern = /custom_tag/
          end

          it "does not log debug messages that match the custom pattern" do
            expect { MultiLogger.debug("custom_tag message") }.not_to output.to_stdout_from_any_process
          end

          it "logs debug messages that match the default pattern" do
            expect { MultiLogger.debug(ignored_message) }.to output(/#{ignored_message}/).to_stdout_from_any_process
          end
        end

        context "when ignore_pattern is built from log_filter config value" do
          it "ignores messages matching a pattern built from a single String" do
            MultiLogger.instance.ignore_pattern = Regexp.union(Array("custom_tag").map(&:to_s))
            expect { MultiLogger.debug("custom_tag message") }.not_to output.to_stdout_from_any_process
          end

          it "ignores messages matching a pattern built from an Array of Strings" do
            filters = ["custom_tag", "another_tag"]
            MultiLogger.instance.ignore_pattern = Regexp.union(Array(filters).map(&:to_s))
            expect { MultiLogger.debug("custom_tag message") }.not_to output.to_stdout_from_any_process
            expect { MultiLogger.debug("another_tag message") }.not_to output.to_stdout_from_any_process
            expect { MultiLogger.debug(debug_message) }.to output(/#{debug_message}/).to_stdout_from_any_process
          end
        end
      end
    end

    describe "#ignore_pattern" do
      it "defaults to DEFAULT_IGNORE_PATTERN" do
        expect(MultiLogger.instance.ignore_pattern).to eq(MultiLogger::DEFAULT_IGNORE_PATTERN)
      end
    end

    describe "#warn" do
      it "logs warning level messages to $stderr" do
        expect { MultiLogger.warn(warn_message) }.to output(/#{warn_message}/).to_stderr_from_any_process
      end
    end

    describe "#error" do
      it "logs error level messages to $stderr" do
        expect { MultiLogger.error(error_message) }.to output(/#{error_message}/).to_stderr_from_any_process
      end
    end

    describe "working with logfile" do
      require "tempfile"
      let(:logfile) { Tempfile.new("test").path }
      before do
        @stdout = $stdout
        @stderr = $stderr

        $stdout = StringIO.new
        $stderr = StringIO.new
      end

      after do
        $stdout = @stdout
        $stderr = @stderr
      end

      it "writes logs to a file instead of $stdout or $stderr" do
        MultiLogger.info(message)
        MultiLogger.error(error_message)
        expect(File.read(logfile)).to include(message)
        expect(File.read(logfile)).to include(error_message)
        expect($stdout.string).to be_empty
        expect($stderr.string).to be_empty
      end
    end
  end
end
