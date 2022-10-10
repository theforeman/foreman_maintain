module Checks::ForemanTasks
  class NotPaused < ForemanMaintain::Check
    include ForemanMaintain::Concerns::Hammer
    metadata do
      for_feature :foreman_tasks
      description 'Check for paused tasks'
      tags :default
      after :services_up, :server_ping
    end

    def run
      paused_tasks_count = feature(:foreman_tasks).paused_tasks_count()
      assert(paused_tasks_count == 0,
        "There are currently #{paused_tasks_count} paused tasks in the system",
        :next_steps => next_procedures)
    end

    def next_procedures
      if assumeyes?
        return [Procedures::ForemanTasks::Resume.new,
                Procedures::ForemanTasks::Delete.new(:state => :paused)]
      end
      [Procedures::ForemanTasks::Resume.new,
       Procedures::ForemanTasks::Delete.new(:state => :paused),
       Procedures::ForemanTasks::UiInvestigate.new('search_query' => 'state = paused')]
    end
  end
end
