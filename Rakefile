# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "bump version and generate CHANGELOG with the version"
task :bump, :type do |_, args|
  require "bump"
  label = args[:type]
  unless %w[major minor patch pre no].include?(label)
    raise "Usage: rake bump[LABEL] (LABEL: ['major', 'minor', 'patch', 'pre', 'no'])"
  end

  next_version = if label == "no"
    Bump::Bump.current
  else
    Bump::Bump.next_version(label)
  end

  require "github_changelog_generator/task"
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    gemspec_path = Dir.glob(File.join(File.dirname(File.expand_path(__FILE__)), "*.gemspec")).first
    gemspec = Gem::Specification.load(gemspec_path)
    config.user = gemspec.authors.first
    config.project = gemspec.name
    config.exclude_labels = ["duplicate", "question", "invalid", "wontfix", "Duplicate", "Question", "Invalid", "Wontfix", "Meta: Exclude From Changelog", "cannot reproduce"]
    config.future_release = "v#{next_version}"
  end

  Rake::Task[:changelog].execute

  puts "update CHANGELOG"
  `git add CHANGELOG.md`

  if label == "no"
    puts "No bump version"
    `git commit -m "update CHANGELOG"`
  else
    puts "Bump version to #{label}"
    Bump::Bump.run(label)
  end

  puts 'Next step: "bundle exec rake release_tag"'
end

desc "Create and Push tag"
task :release_tag do
  require "bundler/gem_tasks"
  Rake::Task["release:source_control_push"].invoke
end

namespace :rbs do
  desc "Generate RBS files for Fusuma"
  task setup: %i[clean collection prototype inline subtract]

  desc "Clean up RBS files"
  task :clean do
    sh 'rm', '-rf', 'sig/generated/'
    sh 'rm', '-rf', 'sig/prototype/'
    sh 'rm', '-rf', '.gem_rbs_collection/'
  end

  desc "Install RBS collection"
  task :collection do
    sh 'rbs', 'collection', 'install'
  end

  desc "Generate RBS files for Fusuma"
  task :prototype do
    sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'lib'
  end

  desc "Generate inline RBS files"
  task :inline do
    # output rbs files from inline to sig/generated
    # $ bundle exec rbs-inline lib --opt-out --output
    sh 'rbs-inline', '--opt-out', 'lib', '--output', '--base', '.'
  end

  desc "Subtract RBS files to create a minimal signature"
  task :subtract do
    sh 'rbs', 'subtract', '--write', 'sig/prototype', 'sig/generated'
    # rbs subtract --write sig/prototype sig/generated

    prototype_path = 'sig/prototype'
    generated_path = 'sig/generated'
    subtrahends = Dir['sig/*']
      .reject { |path| path == prototype_path || path == generated_path }
      .map { |path| "--subtrahend=#{path}" }
    sh 'rbs', 'subtract', '--write', 'sig/prototype', 'sig/generated', *subtrahends
  end

  desc "Validate RBS files"
  task :validate do
    sh 'rbs', '-Isig', 'validate'
  end
end
