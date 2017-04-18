module Checks::ForemanTasks
  class NotPaused < ForemanMaintain::Check
    metadata do
      for_feature :foreman_tasks
      description 'check for paused tasks'
      tags :default
    end

    def run
      paused_tasks_count = feature(:foreman_tasks).paused_tasks_count(ignored_tasks)
      assert(paused_tasks_count == 0,
             "There are currently #{paused_tasks_count} paused tasks in the system",
             :next_steps =>
               [Procedures::ForemanTasks::Resume.new,
                Procedures::ForemanTasks::UiInvestigate.new('search_query' => scoped_search_query)])
    end

    # Note: this is for UI link generation only: we are not using scoped search for querying
    # the tasks itself as we use direct SQL instead
    def scoped_search_query
      "state = paused AND label !^(#{ignored_tasks.join(' ')})"
    end

    def ignored_tasks
      %w[Actions::Candlepin::ListenOnCandlepinEvents
         Actions::Katello::EventQueue::Monitor]
    end
  end
end
