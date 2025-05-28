# frozen_string_literal: true

require "bundler/setup"
require "rspec/debug"

require "helpers/config_helper"
require "simplecov"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include(Fusuma::ConfigHelper)

  # rbs-trace
  begin
    require "rbs-trace"
    trace = RBS::Trace.new

    config.before(:suite) { trace.enable }
    config.after(:suite) do
      trace.disable
      trace.save_comments(:rbs_colon)
    end
  end
end

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start
