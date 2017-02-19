class Procedures::PresentServiceRestart < ForemanMaintain::Procedure
  for_feature(:present_service)
  label :present_service_restart
  tags :restart
  description 'restart present service'

  def run
    feature(:present_service).restart
  end
end
