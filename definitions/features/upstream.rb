class Features::Upstream < ForemanMaintain::Feature
  label :upstream

  confine do
    !downstream_installation?
  end
end
