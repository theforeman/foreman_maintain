module Checks::ForemanTasks
  module Invalid
    class CheckOld < ForemanMaintain::Check
      metadata do
        label :check_old_foreman_tasks
        for_feature :foreman_tasks
        tags :pre_upgrade
        description 'Check for old tasks in paused/stopped state'
      end

      def run
        # Check and delete 'all tasks beyond 30 days(paused and stopped)'
        count_old_tasks = feature(:foreman_tasks).count(:old)
        assert(count_old_tasks <= 0,
               "Found #{count_old_tasks} paused or stopped task(s) older than 30 days",
               :next_steps => Procedures::ForemanTasks::Delete.new(:state => :old))
      end
    end
  end
end
