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
    config.future_release = next_version
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
