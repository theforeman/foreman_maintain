class Features::Downstream < ForemanMaintain::Feature
  feature_name :downstream

  detect do
    new if downstream_installation?
  end
end
