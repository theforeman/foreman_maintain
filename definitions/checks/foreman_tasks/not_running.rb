module Checks::ForemanTasks
  class NotRunning < ForemanMaintain::Check
    metadata do
      for_feature :foreman_tasks
      description 'Check for running tasks'
      tags :pre_upgrade
      after :foreman_tasks_not_paused
      before :check_old_foreman_tasks
      param :wait_time, 'Time to wait in minutes for foreman tasks to finish'
    end

    def run
      task_count = feature(:foreman_tasks).running_tasks_count
      assert(task_count == 0,
             failure_message(task_count),
             :next_steps => next_steps)
    end

    def next_steps
      procedure = [Procedures::ForemanTasks::UiInvestigate.new(
        'search_query' => search_query_for_running_tasks
      )]
      if @wait_time
        procedure.unshift(Procedures::ForemanTasks::FetchTasksStatus.new(
                            :state => 'running', :wait_time => @wait_time
        ))
      else
        procedure.unshift(Procedures::ForemanTasks::FetchTasksStatus.new(:state => 'running'))
      end
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
