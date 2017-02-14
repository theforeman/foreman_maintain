class Features::MissingService < ForemanMaintain::Feature
  label :missing_service

  detect do
    # simulate this service is not present on the system
  end
end
