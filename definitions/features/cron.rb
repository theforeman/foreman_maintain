class Features::Cron < ForemanMaintain::Feature
  metadata do
    label :cron
    confine do
      ForemanMaintain.config.manage_crond
    end
  end

  def status_for_maintenance_mode(mode_on)
    cron_service = system_service(service_name)
    if cron_service.running?
      [
        'cron jobs: running',
        mode_on ? [Procedures::Service::Stop.new(:only => [cron_service])] : [],
      ]
    else
      [
        'cron jobs: not running',
        mode_on ? [] : [Procedures::Service::Start.new(:only => [cron_service])],
      ]
    end
  end

  def service_name
    'crond'
  end
end
