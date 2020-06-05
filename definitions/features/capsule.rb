class Features::Capsule < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Downstream

  metadata do
    label :capsule

    confine do
      !package_manager.installed?(['satellite']) &&
        package_manager.installed?(['satellite-capsule']) ||
        package_manager.installed?(['capsule-installer'])
    end
  end

  def current_version
    @current_version ||= rpm_version(package_name)
  end

  def package_name
    'satellite-capsule'
  end
end
