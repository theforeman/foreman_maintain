module Checks::ForemanRake
  class KatelloUpgradeCheck < ForemanMaintain::Check
    metadata do
      label :katello_upgrade_check
      tags :pre_upgrade
      description 'Check for active tasks using katello:upgrade_check'
      confine do
        feature(:katello) && command_exists?('foreman-rake')
      end
    end

    def run
      output = execute('foreman-rake katello:upgrade_check')
      assert(ready_to_upgrade?(output),
             output,
             :next_steps =>
                [Procedures::ForemanTasks::Resume.new,
                 Procedures::ForemanTasks::UiInvestigate.new('search_query' => 'state = paused')])
    end

    private

    def ready_to_upgrade?(output)
      /PASS/ =~ output
    end
  end
end
