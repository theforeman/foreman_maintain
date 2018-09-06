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
      system_service('crond', 5)
    ]
  end

  def status_for_maintenance_mode(mode_on)
    if services[0].running?
      [
        'cron jobs: running',
        mode_on ? [Procedures::Service::Stop.new(:only => 'crond')] : []
      ]
    else
      [
        'cron jobs: not running',
        mode_on ? [] : [Procedures::Service::Start.new(:only => 'crond')]
      ]
    end
  end
end
