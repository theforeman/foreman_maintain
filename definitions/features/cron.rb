class Features::Cron < ForemanMaintain::Feature
  metadata do
    label :cron
    confine do
      ForemanMaintain.config.manage_crond && !(
        feature(:downstream) && feature(:downstream).less_than_version?('6.3')
      )
    end
  end

  def services
    # TODO: For debian, add cron as service
    [
      system_service('crond', 5, :register => false)
    ]
  end

  def status_for_maintenance_mode(mode_on)
    if services[0].running?
      [
        'cron jobs: running',
        mode_on ? [Procedures::Service::Stop.new(service_options)] : []
      ]
    else
      [
        'cron jobs: not running',
        mode_on ? [] : [Procedures::Service::Start.new(service_options)]
      ]
    end
  end

  def service_options
    {
      :only => 'crond', :include_unregister => true
    }
  end
end
