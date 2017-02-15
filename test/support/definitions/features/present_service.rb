class Features::PresentService < ForemanMaintain::Feature
  label :present_service
  autodetect

  confine do
    0.zero?
  end

  def start
    # pretend we start the service
  end

  def restart
    # pretend we restart the service
  end
end
