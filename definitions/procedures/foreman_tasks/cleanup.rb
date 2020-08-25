module Procedures::ForemanTasks
  class Cleanup < ForemanMaintain::Procedure
    PERMITTED_STATES = %w[all pending scheduled planning planned running paused stopped].freeze
    metadata do
      for_feature :foreman_tasks
      description 'Perform task cleanup'
      preparation_steps { Checks::Foreman::DBUp.new }
      confine do
        feature(:foreman) && feature(:foreman_tasks)
      end

      param :states,
            'Operate on tasks in STATES' \
             "\nAvailable states: " + PERMITTED_STATES.join(', '),
            :array => true, :allowed_values => PERMITTED_STATES
      param :batch_size,
            'Process tasks in batches of BATCH_SIZE, 1000 by default' do |s|
        Integer(s) unless s.nil?
      end
      param :after,
            'Operate on tasks older than AFTER. Expected format is a number ' \
            "followed by the time unit (s,h,d,m,y), such as '10d' for 10 days"
      param :backup, 'Backup deleted tasks', :flag => true
      param :noop, 'Do a dry run, print what would be done', :flag => true
      param :search, 'Use QUERY in scoped search format to match tasks to delete'
      param :rake_command, 'Use RAKE_COMMAND as rake', :default => 'foreman-rake'
      param :verbose, 'Be verbose', :flag => true
      param :generate, 'Only generate the resulting command, do not run it', :flag => true
    end

    def run
      f = feature(:foreman_tasks)

      # If states are provided, then a search must be provided as well
      # We assume if the user didn't provide a search query, they want to match
      # all tasks in given stat so we provide a bogus search value which matches
      # all tasks
      @search = 'label != a_label' if !@states.empty? && @search.nil?
      args = [@rake_command, @batch_size, @states, @after, @search, @backup, @noop, @verbose]

      cleanup_command = f.generate_task_cleanup_command(*args)
      if @generate
        puts cleanup_command
      else
        message = 'Performing task cleanup'
        with_spinner(message) do |spinner|
          execute!(cleanup_command) { |line| spinner.update line }
          spinner.update(message)
        end
      end
    end
  end
end
