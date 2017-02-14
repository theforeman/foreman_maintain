class Checks::MissingServiceIsRunning < ForemanMaintain::Check
  # simulate a check defined for service that is not present on the system
  for_feature(:missing_feature)
  tags :basic
  description 'missing service is running check'

  def run
    assert(feature(:missing_service).running?,
           'The missing service is not running')
  end
end
