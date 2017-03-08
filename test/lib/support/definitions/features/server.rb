class Features::Server < ForemanMaintain::Feature
  metadata do
    label :server

    confine do
      true
    end
  end

  def additional_features
    [Features::SubService.new('mailing'),
     Features::SubService.new('logging')]
  end
end
