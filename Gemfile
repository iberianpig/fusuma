# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in fusuma.gemspec
gemspec

gem "bundler"
gem "debug"
gem "rake", "~> 13.0"
gem "rblineprof"
gem "rblineprof-report"
gem "reek"
gem "rspec", "~> 3.0"
gem "rspec-debug"
gem "rspec-parameterized"

# release management
gem "bump", require: false
gem "github_changelog_generator", "~> 1.16", require: false

gem "simplecov", require: false
gem "standard", require: false

# generate rbs files
if RUBY_VERSION >= "3.1.0"
  gem "rbs-trace", "~> 0.6.0", require: false
  gem "rbs-inline", require: false
end

# typecheck
gem "steep", require: false

# irb completion using rbs (Ruby 3.0+ only)
if RUBY_VERSION >= "3.0.0"
  gem "repl_type_completor", require: false
end
