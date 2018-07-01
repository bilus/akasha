require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task 'release' => ['release:source_control_push'] do # Travis will take care of the rest.
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--rails', '--display-cop-names']
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
