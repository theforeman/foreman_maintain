require 'rake/testtask'
require 'fileutils'

namespace :test do
  Rake::TestTask.new(:lib) do |t|
    t.libs << 'lib' << 'test/lib'
    t.test_files = FileList['test/lib/**/*_test.rb']
    t.verbose = true
    t.warning = false
  end

  Rake::TestTask.new(:definitions) do |t|
    t.libs << 'lib' << 'test/definitions'
    t.test_files = FileList['test/definitions/**/*_test.rb']
    t.verbose = true
    t.warning = false
  end
end
task :test => ['test:lib', 'test:definitions']

require 'rubocop/rake_task'
RuboCop::RakeTask.new
task :default => [:rubocop, :test]
