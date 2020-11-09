module ForemanMaintain::Scenarios
  class Prep610Upgrade < ForemanMaintain::Scenario
    metadata do
      label :prep_6_10_upgrade
      description 'Preparations for the Satellite 6.10 upgrade'
      manual_detection
    end

    def compose
      add_step(Procedures::Prep610Upgrade)
    end
  end
end
