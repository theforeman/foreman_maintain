class Checks::ServiceIsStopped < ForemanMaintain::Check
  metadata do
    for_feature(:present_service)
    label :service_is_stopped
    tags :default
    description 'service not running check'
    preparation_steps { Procedures::Setup.new }
  end

  def run
    assert(false, 'service is running',
           :next_steps => Procedures::StopService.new)
  end
end
