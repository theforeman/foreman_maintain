class Checks::ForemanTasksNotPaused < ForemanMaintain::Check
  metadata do
    for_feature :foreman_tasks
    description 'check for paused tasks'
    tags :basic
  end

  def run
    paused_tasks_count = feature(:foreman_tasks).paused_tasks_count
    assert(paused_tasks_count == 0,
           "There are currently #{paused_tasks_count} paused tasks in the system",
           :next_steps =>
             [Procedures::ForemanTasksResume.new,
              Procedures::ForemanTasksUiInvestigate.new('search_query' => 'state = paused')])
  end
end
