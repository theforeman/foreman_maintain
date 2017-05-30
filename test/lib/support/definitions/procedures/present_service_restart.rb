class Procedures::PresentServiceRestart < ForemanMaintain::Procedure
  metadata do
    for_feature(:present_service)
    label :present_service_restart
    tags :restart
    description 'restart present service'
    after :service_is_stopped
  end

  def run
    feature(:present_service).restart
  end
end
