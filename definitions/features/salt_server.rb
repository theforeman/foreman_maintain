class Features::SaltServer < ForemanMaintain::Feature
  metadata do
    label :salt_server

    confine do
      find_package('salt-master') &&
        ForemanMaintain::Utils::Service::Systemd.new('salt-master', 0).exist? &&
        ForemanMaintain::Utils::Service::Systemd.new('salt-master', 0).enabled?
    end
  end

  def config_files
    [
      '/etc/salt'
    ]
  end

  def services
    salt_services = [system_service('salt-master', 30)]
    if ForemanMaintain::Utils::Service::Systemd.new('salt-api', 0).exist? &&
       ForemanMaintain::Utils::Service::Systemd.new('salt-api', 0).enabled?
      salt_services += [system_service('salt-api', 30)]
    end
    salt_services
  end
end
