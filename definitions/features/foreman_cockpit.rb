class Features::ForemanCockpit < ForemanMaintain::Feature
  metadata do
    label :foreman_cockpit

    confine do
      server? && find_scl_or_nonscl_package('rubygem-foreman_remote_execution-cockpit')
    end
  end

  def services
    [
      system_service('foreman-cockpit')
    ]
  end
end
