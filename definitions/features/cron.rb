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
    { 'crond' => 5 }
  end
end
