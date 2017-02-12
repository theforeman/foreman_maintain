class Checks::ForemanTasksNotPaused < ForemanMaintain::Check
  requires_feature :foreman_tasks
  tags :basic

  def run
    feature(:foreman_tasks).paused_tasks_count
  end
end
