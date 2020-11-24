module Procedures::ForemanTasks
  class Resume < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::Hammer
    metadata do
      for_feature :foreman_tasks
      description 'Resume paused tasks'
    end

    def run
      output << feature(:foreman_tasks).resume_task_using_hammer
      with_spinner('Waiting 30 seconds for resumed tasks to start.') do
        sleep 30
      end
    end
  end
end
