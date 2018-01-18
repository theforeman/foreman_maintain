class Features::Upstream < ForemanMaintain::Feature
  metadata do
    label :upstream

    confine do
      !downstream_installation?
    end
  end

  def current_version
    @current_version ||= package_version('foreman')
  end

  def current_minor_version
    current_version.to_s[/^\d+\.\d+/]
  end

  def setup_repositories(version)
    distros.upgrade_version = version
    distros.setup_repositories
  end
end
