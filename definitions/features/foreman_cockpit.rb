class Features::ForemanCockpit < ForemanMaintain::Feature
  metadata do
    label :foreman_cockpit

    confine do
      server? && plugin_package(:cockpit)
    end
  end

  def services
    [
      system_service('foreman-cockpit')
    ]
  end
end
