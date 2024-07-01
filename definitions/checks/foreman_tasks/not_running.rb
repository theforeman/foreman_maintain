module Checks::ForemanTasks
  class NotRunning < ForemanMaintain::Check
    metadata do
      for_feature :foreman_tasks
      description 'Check for running tasks'
      tags :pre_upgrade
      after :foreman_tasks_not_paused
      before :check_old_foreman_tasks
      param :wait_for_tasks,
        'Wait for tasks to finish or fail directly',
        :required => false,
        :default => true
    end

    def run
      task_count = feature(:foreman_tasks).running_tasks_count
      assert(task_count == 0,
        failure_message(task_count),
        :next_steps => calculate_next_steps)
    end

    private

    def search_query_for_running_tasks
      'state = running AND '\
      "label !^(#{Features::ForemanTasks::EXCLUDE_ACTIONS_FOR_RUNNING_TASKS.join(' ')})"
    end

    def failure_message(task_count)
      "There are #{task_count} active task(s) in the system." \
      "\nPlease wait for these to complete or cancel them from the Monitor tab."
    end

    def calculate_next_steps
      steps = []
      if @wait_for_tasks
        steps << Procedures::ForemanTasks::FetchTasksStatus.new(:state => 'running')
        unless assumeyes?
          steps << Procedures::ForemanTasks::UiInvestigate.new(
            'search_query' => search_query_for_running_tasks
          )
        end
      end
      steps
    end
  end
end
