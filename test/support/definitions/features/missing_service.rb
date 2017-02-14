class Features::MissingService < ForemanMaintain::Feature
  label :missing_service
  autodetect

  confine do
    # simulate this service is not present on the system
    false
  end
end
