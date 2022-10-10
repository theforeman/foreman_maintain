class Checks::MissingServiceIsRunning < ForemanMaintain::Check
  metadata do
    # simulate a check defined for service that is not present on the system
    for_feature(:missing_service)
    tags :default
    description 'Missing service is running check'
  end

  def run
    assert(feature(:missing_service).running?,
      'The missing service is not running')
  end
end
