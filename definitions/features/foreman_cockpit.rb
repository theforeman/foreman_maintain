class Features::ForemanCockpit < ForemanMaintain::Feature
  metadata do
    label :foreman_cockpit

    confine do
      server? && find_package(foreman_plugin_name('foreman_remote_execution-cockpit'))
    end
  end

  def services
    [
      system_service('foreman-cockpit'),
    ]
  end
end
