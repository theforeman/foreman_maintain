class Features::Upstream < ForemanMaintain::Feature
  feature_name :upstream

  detect do
    new unless downstream_installation?
  end
end
