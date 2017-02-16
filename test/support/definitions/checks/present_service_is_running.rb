class Checks::PresentServiceIsRunning < ForemanMaintain::Check
  label :present_service_is_running
  for_feature(:present_service)
  tags :basic
  description 'present service run check'

  def run
    assert(feature(:present_service).running?,
           'present service is not running')
  end
end
