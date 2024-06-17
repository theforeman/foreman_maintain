module Procedures::Pulpcore
  class WaitForTasks < ForemanMaintain::Procedure
    metadata do
      for_feature :pulpcore
      description 'Fetch tasks status and wait till they finish'
      advanced_run false
    end

    def run
      with_spinner("waiting for tasks to finish") do |spinner|
        feature(:pulpcore).wait_for_tasks(spinner)
      end
    end
  end
end
