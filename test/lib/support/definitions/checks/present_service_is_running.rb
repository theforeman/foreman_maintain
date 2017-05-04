class Checks::PresentServiceIsRunning < ForemanMaintain::Check
  metadata do
    label :present_service_is_running
    for_feature(:present_service)
    tags :default
    description 'present service run check'
    preparation_steps { Procedures::Setup.new }
  end

  def run
    assert(feature(:present_service).running?,
           'present service is not running',
           :next_steps => Procedures::PresentServiceStart.new)
  end
end
