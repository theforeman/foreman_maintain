class Features::Pulp < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::DirectoryMarker

  metadata do
    label :pulp2

    confine do
      find_package('pulp-server') && !check_min_version('katello-common', '4.0')
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

  def exclude_from_backup
    # Exclude /var/lib/pulp/katello-export and /var/lib/pulp/cache
    # since the tar is run from /var/lib/pulp, list subdir paths only
    ['katello-export', 'cache']
  end
end
