class Features::MissingService < ForemanMaintain::Feature
  metadata do
    label :missing_service

    confine do
      # simulate this service is not present on the system
      false
    end
  end

  def restart
    # pretend we restart the service
  end
end
