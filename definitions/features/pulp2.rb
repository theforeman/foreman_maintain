class Features::Pulp < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::DirectoryMarker
  include ForemanMaintain::Concerns::PulpCommon

  metadata do
    label :pulp2

    confine do
      !check_min_version('katello-common', '4.0') &&
        ForemanMaintain::Utils::Service::Systemd.new('pulp_resource_manager', 0).enabled?
    end
  end

  def services
    [
      system_service('squid', 10),
      system_service('qpidd', 10),
      system_service('qdrouterd', 10),
      system_service('pulp_workers', 20),
      system_service('pulp_celerybeat', 20),
      system_service('pulp_resource_manager', 20),
      system_service('pulp_streamer', 20),
      system_service('httpd', 30),
    ]
  end

  def config_files
    [
      '/etc/pki/pulp',
      '/etc/pulp',
      '/etc/crane.conf',
      '/etc/default/pulp_workers',
    ]
  end
end
