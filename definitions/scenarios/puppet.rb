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
        add_step(Checks::CheckPuppetCapsules) if server?
        add_step(Procedures::Puppet::RemovePuppet)
        add_step(Procedures::Puppet::RemovePuppetData) if context.get(:remove_data)
        add_step(Procedures::Service::Restart)
      end
    end
  end
end
