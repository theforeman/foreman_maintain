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
      add_step(Procedures::SyncPlans::Disable.new)
      puts feature(:cron).inspect
      if feature(:cron)
        cron_service = feature(:cron).services.key(5)
        add_step(Procedures::Service::Stop.new(:only => cron_service))
      end
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
      add_step(Procedures::SyncPlans::Enable.new)
      if feature(:cron)
        cron_service = feature(:cron).services.key(5)
        add_step(Procedures::Service::Start.new(:only => cron_service))
      end
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
      add_step(Procedures::MaintenanceMode::Check.new)
    end
  end

  class IsMaintenanceMode < ForemanMaintain::Scenario
    metadata do
      description 'Show only status code of maintenance-mode'
      tags :is_maintenance_mode_enabled
      label :is_maintenance_mode_enabled
      manual_detection
    end

    def compose
      add_step(Procedures::MaintenanceMode::IsEnabled.new)
    end
  end
end
