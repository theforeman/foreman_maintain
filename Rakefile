require 'rake/testtask'
require 'fileutils'

namespace :test do
  Rake::TestTask.new(:lib) do |t|
    t.libs << 'lib' << 'test/lib'
    t.test_files = FileList['test/lib/*_test.rb']
    t.verbose = true
    t.warning = false
  end
end
task :test => ['test:lib']

if RUBY_VERSION >= '2.0'
  # Latest ruobcop doesn't work with Ruby 1.8.7, but unless it let's us to
  # write 1.8.7-compatible code, we are ok
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  task :default => [:rubocop, :test]
else
  task :default => [:test]
end
