module Checks::ForemanTasks
  class NotRunning < ForemanMaintain::Check
    metadata do
      for_feature :foreman_tasks
      description 'Check for running tasks'
      tags :pre_upgrade
      after :foreman_tasks_not_paused
      before :check_old_foreman_tasks
    end

    def run
      task_count = feature(:foreman_tasks).running_tasks_count
      assert(task_count == 0,
        failure_message(task_count),
        :next_steps =>
          [Procedures::ForemanTasks::FetchTasksStatus.new(:state => 'running'),
           Procedures::ForemanTasks::UiInvestigate.new(
             'search_query' => search_query_for_running_tasks
           )])
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
  end
end
