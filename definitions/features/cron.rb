class Features::Cron < ForemanMaintain::Feature
  metadata do
    label :cron
    confine do
      ForemanMaintain.config.manage_crond && !(
        feature(:downstream) && feature(:downstream).less_than_version?('6.3')
      )
    end
  end

  def status_for_maintenance_mode(mode_on)
    if system_service(service_name).running?
      [
        'cron jobs: running',
        mode_on ? [Procedures::Service::Stop.new(:only => service_name)] : []
      ]
    else
      [
        'cron jobs: not running',
        mode_on ? [] : [Procedures::Service::Start.new(:only => service_name)]
      ]
    end
  end

  def service_name
    'crond'
  end
end
