module ForemanMaintain
  module Cli
    class TaskCleanupCommand < Base
      include Concerns::SystemHelpers

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
        command = generate_rake.shelljoin
        if generate?
          reporter.puts command
        else
          raise 'Task cleanup can be executed only on the foreman server' unless server?
          execute! command
        end
      end

      private

      def generate_rake
        [
          rake_command.shellsplit,
          'foreman_tasks:cleanup',
          format_key_value('BATCH_SIZE', batch_size),
          # Somewhat counterintuitively, passing empty string into the rake
          #   causes it to match tasks in all states
          format_key_value('STATES', states == %w(all) ? [] : states),
          format_key_value('AFTER', after),
          format_key_value('TASK_SEARCH', search),
          format_key_value('TASK_BACKUP', backup?),
          format_key_value('NOOP', noop?),
          format_key_value('VERBOSE', verbose?)
        ].flatten.compact
      end

      def format_key_value(key, value)
        out_value = case value
                    when true
                      1
                    when false
                      0
                    when Array
                      value.join(',')
                    else
                      value
                    end
        "#{key}=#{out_value}" if out_value
      end
    end
  end
end
