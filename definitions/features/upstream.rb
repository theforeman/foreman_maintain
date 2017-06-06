class Features::Upstream < ForemanMaintain::Feature
  metadata do
    label :upstream

    confine do
      !downstream_installation?
    end
  end

  def set_repositories(_version)
    raise NotImplementedError
  end
end
