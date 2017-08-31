module Procedures::ForemanTasks
  class Resume < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_tasks
      description 'Resume paused tasks'
    end

    def run
      output << feature(:foreman_tasks).resume_task_using_hammer
    end
  end
end
