class Checks::ForemanTasksNotRunning < ForemanMaintain::Check
  requires_feature :foreman_tasks
  description "check for running tasks"

  def run
    assert(feature(:foreman_tasks).running_tasks_count == 0,
           "There are actively running tasks in the system")
  end
end
