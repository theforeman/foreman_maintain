class Features::Pulp < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::DirectoryMarker

  metadata do
    label :pulp2

    confine do
      find_package('pulp-server')
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
      system_service('httpd', 30)
    ]
  end

  def data_dir
    '/var/lib/pulp'
  end

  def config_files
    [
      '/etc/pki/pulp',
      '/etc/pulp',
      '/etc/crane.conf',
      '/etc/default/pulp_workers'
    ]
  end
end
