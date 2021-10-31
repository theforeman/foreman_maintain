module Scenarios::Puppet
  class RemovePuppet < ForemanMaintain::Scenario
    metadata do
      description 'Remove Puppet feature'
      tags :puppet_disable
      label :puppet_disable
      param :remove_data, 'Purge the Puppet data after disabling plugin'
      manual_detection
    end

    def compose
      add_steps([Checks::Dummy::Success])
    end
  end
end
