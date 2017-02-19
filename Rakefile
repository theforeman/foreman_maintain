require 'rake/testtask'
require 'rubocop/rake_task'
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

RuboCop::RakeTask.new

task :default => [:rubocop, :test]
