class Features::Downstream < ForemanMaintain::Feature
  label :downstream

  confine do
    downstream_installation?
  end
end
