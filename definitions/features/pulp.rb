class Features::Pulp < ForemanMaintain::Feature
  metadata do
    label :pulp

    confine do
      find_package('pulp-server')
    end
  end

  def services
    {
      'squid'                    => 10,
      'pulp_workers'             => 20,
      'pulp_celerybeat'          => 20,
      'pulp_resource_manager'    => 20,
      'pulp_streamer'            => 20
    }
  end

  def data_dir
    '/var/lib/pulp'
  end

  def config_files
    [
      '/etc/pki/pulp',
      '/etc/pulp',
      '/etc/qpid',
      '/etc/qpid-dispatch',
      '/etc/crane.conf',
      '/etc/default/pulp_workers',
      '/var/lib/qpidd',
      '/etc/qpid-dispatch'
    ]
  end

  def find_base_directory(directory)
    find_dir_containing_file(directory, '0005_puppet_module_name_change.txt')
  end
end
