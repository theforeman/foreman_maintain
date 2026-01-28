class Features::RhCloud < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Versions

  metadata do
    label :rh_cloud

    confine do
      find_package(foreman_plugin_name('foreman_rh_cloud'))
    end
  end

  def current_version
    @current_version ||= package_version(package_name)
  end

  def package_name
    foreman_plugin_name('foreman_rh_cloud')
  end
end
