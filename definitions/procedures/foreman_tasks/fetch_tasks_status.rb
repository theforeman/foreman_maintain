module Procedures::ForemanTasks
  class FetchTasksStatus < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_tasks
      description 'Fetch tasks status and wait till they finish'
      param :state, :required => true
    end

    def run
      with_spinner("waiting for #{@state} tasks to finish") do |spinner|
        feature(:foreman_tasks).fetch_tasks_status(@state, spinner)
      end
    end
  end
end
