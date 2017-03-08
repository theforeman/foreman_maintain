class Features::Upstream < ForemanMaintain::Feature
  metadata do
    label :upstream

    confine do
      !downstream_installation?
    end
  end
end
