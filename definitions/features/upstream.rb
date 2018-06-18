class Features::Upstream < ForemanMaintain::Feature
  MIN_MEM = 4_100_000
  DISPLAY_MEM = 4

  metadata do
    label :upstream

    confine do
      !downstream_installation?
    end
  end

  def min_mem
    MIN_MEM
  end

  def display_mem
    DISPLAY_MEM
  end

  def setup_repositories(_version)
    raise NotImplementedError
  end
end
