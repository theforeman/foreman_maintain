class Checks::ForemanTasksNotPaused < ForemanMaintain::Check
  for_feature :foreman_tasks
  description 'check for paused tasks'
  tags :basic

  def run
    assert(feature(:foreman_tasks).paused_tasks_count == 0,
           'There are currently paused tasks in the system')
  end

  def next_steps
    [procedure(Procedures::ForemanTasksResume)] if fail?
  end
end
