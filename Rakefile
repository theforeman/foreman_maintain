require 'rake/testtask'
require 'rubocop/rake_task'
require 'fileutils'

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = false
end

RuboCop::RakeTask.new

task :default => [:rubocop, :test]
