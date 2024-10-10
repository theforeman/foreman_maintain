class Features::Satellite < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Downstream
  include ForemanMaintain::Concerns::Versions

  metadata do
    label :satellite

    confine do
      package_manager.installed?(['satellite'])
    end
  end

  def target_version
    satellite_maintain_target_version
  end

  def current_version
    @current_version ||= package_version(package_name)
  end

  def package_name
    'satellite'
  end

  def module_name
    'satellite'
  end
end
