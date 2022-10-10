module Checks::ForemanTasks
  module Invalid
    class CheckPendingState < ForemanMaintain::Check
      metadata do
        label :check_foreman_tasks_in_pending_state
        for_feature :foreman_tasks
        tags :pre_upgrade
        description 'Check for pending tasks which are safe to delete'
        before :check_foreman_tasks_in_planning_state
      end

      def run
        # Check and delete 'all tasks in pending state'
        count_tasks_in_pending_state = feature(:foreman_tasks).count(:pending)
        assert(count_tasks_in_pending_state <= 0,
          "Found #{count_tasks_in_pending_state} pending task(s) which are safe to delete",
          :next_steps => Procedures::ForemanTasks::Delete.new(:state => :pending))
      end
    end
  end
end
