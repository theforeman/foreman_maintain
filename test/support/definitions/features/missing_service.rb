class Features::MissingService < ForemanMaintain::Feature
  feature_name :missing_service

  detect do
    # simulate this service is not present on the system
  end
end
