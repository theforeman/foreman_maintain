module Procedures::ForemanTasks
  class FetchTasksStatus < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_tasks
      description 'Fetch tasks status and wait till they finish'
      param :state, "Specify state of tasks. Either 'running' or 'paused'", :required => true
      param :wait_time, 'Time to wait in minutes for foreman tasks to finish'
      advanced_run false
    end

    def run
      with_spinner("waiting for #{@state} tasks to finish") do |spinner|
        if @wait_time
          timeout_for_tasks_status = @wait_time * 60
          interval_time = (@wait_time * 60) / 10
          retry_interval_for_tasks_state = interval_time > 10 ? interval_time : 10
          feature(:foreman_tasks).fetch_tasks_status(@state, spinner, timeout_for_tasks_status,
                                                     retry_interval_for_tasks_state)
        else
          feature(:foreman_tasks).fetch_tasks_status(@state, spinner)
        end
      end
    end
  end
end
