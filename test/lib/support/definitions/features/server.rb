class Features::Server < ForemanMaintain::Feature
  label :server

  confine do
    true
  end

  def additional_features
    [Features::SubService.new('mailing'),
     Features::SubService.new('logging')]
  end
end
