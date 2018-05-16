module ForemanMaintain::Scenarios
  class MaintenanceModeStart < ForemanMaintain::Scenario
    metadata do
      description 'Start maintenance-mode'
      tags :maintenance_mode_start
      label :maintenance_mode_start
      manual_detection
    end

    def compose
      add_step(Procedures::Iptables::AddChain.new)
      add_step(Procedures::Cron::Stop.new)
      add_step(Procedures::MaintenanceFile::Create.new)
    end
  end

  class MaintenanceModeStop < ForemanMaintain::Scenario
    metadata do
      description 'Stop maintenance-mode'
      tags :maintenance_mode_stop
      label :maintenance_mode_stop
      manual_detection
    end

    def compose
      add_step(Procedures::Iptables::RemoveChain.new)
      add_step(Procedures::Cron::Start.new)
      add_step(Procedures::MaintenanceFile::Remove.new)
    end
  end

  class MaintenanceModeStatus < ForemanMaintain::Scenario
    metadata do
      description 'Status of maintenance-mode'
      tags :maintenance_mode_status
      label :maintenance_mode_status
      manual_detection
    end

    def compose
      add_step(Procedures::MaintenanceFile::Check.new)
    end
  end
end
