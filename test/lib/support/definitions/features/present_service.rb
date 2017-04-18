class Features::PresentService < ForemanMaintain::Feature
  metadata do
    label :present_service

    confine do
      0.zero?
    end
  end

  def start
    # pretend we start the service
  end

  def stop
    # pretend we stop the service
  end

  def restart
    # pretend we restart the service
  end

  def running?
    false
  end
end
