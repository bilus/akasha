require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

namespace 'ci' do
  task 'tag' do
    gemspecs = Dir[File.join(__dir__, '{,*}.gemspec')]
    raise 'No gemspec found' unless gemspecs.size == 1
    spec_path = gemspecs.first
    gemspec = Bundler.load_gemspec(spec_path)
    version_tag = "v#{gemspec.version}"
    return if `git tag`.split(/\n/).include?(version_tag)
    `git tag #{version_tag}`
    `git push --tags`
  end

  task 'release' => ['build', 'release:rubygem_push', 'ci:tag'] do
  end
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--rails', '--display-cop-names']
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
