class Checks::ForemanTasksNotPaused < ForemanMaintain::Check
  requires_feature :foreman_tasks
  description "check for paused tasks"
  tags :basic

  def run
    assert(feature(:foreman_tasks).paused_tasks_count == 0,
           "There are currently paused tasks in the system")
  end
end
