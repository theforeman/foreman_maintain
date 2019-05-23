# TODO: verify and remove if not required
class Features::Upstream < ForemanMaintain::Feature
  metadata do
    label :upstream

    confine do
      !feature(:downstream)
    end
  end

  def setup_repositories(_version)
    raise NotImplementedError
  end
end
