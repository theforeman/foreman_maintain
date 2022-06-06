module ForemanMaintain::Scenarios
  module Puppet
    class RemovePuppet < ForemanMaintain::Scenario
      metadata do
        description 'Remove Puppet feature'
        tags :puppet_disable
        label :puppet_disable
        param :remove_data, 'Purge the Puppet data after disabling plugin'
        manual_detection
      end

      def compose
        if check_min_version('foreman', '3.0') || check_min_version('foreman-proxy', '3.0')
          add_step(Checks::CheckPuppetCapsules) if server?
          add_step(Procedures::Puppet::RemovePuppet)
          add_step(Procedures::Puppet::RemovePuppetData) if context.get(:remove_data)
          add_step(Procedures::Service::Restart)
          if server?
            add_step(Procedures::Foreman::ApipieCache)
          end
        end
      end
    end
  end
end
