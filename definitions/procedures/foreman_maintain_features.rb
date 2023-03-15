class Procedures::ForemanMaintainFeatures < ForemanMaintain::Procedure
  metadata do
    description 'List detected Foreman Maintain features'
  end

  def run
    features = ForemanMaintain.available_features
    output << features.map(&:inspect).join("\n")
  end
end
