class Procedures::RefreshFeatures < ForemanMaintain::Procedure
  metadata do
    description 'Refresh detected features'
  end

  def run
    ForemanMaintain.refresh_features
  end
end
