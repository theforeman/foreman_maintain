module ForemanMaintain::Scenarios
  module Puppet
    class RemovePuppet < ForemanMaintain::Scenario
      metadata do
        description 'Remove Puppet feature'
        tags :puppet_disable
        label :puppet_disable
        param :remove_data, 'Purge the Puppet data after disabling plugin'
        confine do
          check_min_version('foreman', '3.0') || check_min_version('foreman-proxy', '3.0')
        end
        manual_detection
      end

      def compose
        add_step(Checks::CheckPuppetCapsules) if server?
        add_step(Procedures::Puppet::RemovePuppet)
        add_step(Procedures::Puppet::RemovePuppetData) if context.get(:remove_data)
      end
    end
  end
end
