# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'bump'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

require 'github_changelog_generator/task'

task :bump, :type do |_, args|
  type = args[:type]
  unless %w[major minor patch pre].include?(type)
    raise "Usage: rake bump[LABEL] (LABEL: ['major', 'minor', 'patch', 'pre'])"
  end

  next_version = Bump::Bump.next_version(type)

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.user = 'iberianpig'
    config.project = 'fusuma'
    config.future_release = next_version
  end

  Rake::Task[:changelog].execute

  `git add CHANGELOG.md`

  Bump::Bump.run(type)
end
