module Procedures::ForemanTasks
  class Resume < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::Hammer

    metadata do
      for_feature :foreman_tasks
      description 'resume paused tasks'
    end

    def run
      output << hammer('task resume')
    end
  end
end
