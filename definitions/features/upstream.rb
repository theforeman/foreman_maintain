class Features::Upstream < ForemanMaintain::Feature
  metadata do
    label :upstream

    confine do
      # TODO: remove this upstream feature
      !feature(:instance).downstream
    end
  end

  def setup_repositories(_version)
    raise NotImplementedError
  end
end
