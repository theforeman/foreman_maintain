module ForemanMaintain
  module Cli
    class TaskCleanupCommand < Base
      DEFAULT_RAKE_COMMAND = 'foreman-rake'.freeze

      option %w(-B --batch-size), 'BATCH_SIZE', 'Process tasks in batches of BATCH_SIZE, 1000 by default' do |s|
        Integer(s)
      end
      option %w(-S --states), 'STATES', 'Operate on tasks in STATES, comma separated list of states, set to all to operate on tasks in any state' do |s|
        s.split(',')
      end
      option %w(-a --after), 'AGE', "Operate on tasks older than AGE. Expected format is a number followed by the time unit (s,h,m,y), such as '10d' for 10 days"
      option %w(-b --backup), :flag, 'Backup deleted tasks'
      option %w(-n --noop), :flag, 'Do a dry run, print what would be done'
      option %w(-s --search), 'QUERY', 'Use QUERY in scoped search format to match tasks to delete'
      option %w(-r --rake-command), 'RAKE_COMMAND', 'Use RAKE_COMMAND as rake', :default => DEFAULT_RAKE_COMMAND
      option %w(-v --verbose), :flag, 'Be verbose'
      option %w(-G --generate), :flag, 'Only generate the resulting command, do not run it'

      def execute
        f = feature(:foreman_tasks)
        raise ForemanMaintain::Error::Fail, 'foreman_tasks feature missing' if f.nil?
        args = [rake_command, batch_size, states, after, search, backup?, noop?, verbose?]
        if generate?
          reporter.puts f.generate_task_cleanup_command(*args)
        else
          f.task_cleanup(*args)
        end
      end
    end
  end
end
