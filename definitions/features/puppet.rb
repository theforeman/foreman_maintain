class Features::Puppet < ForemanMaintain::Feature
  metadata do
    label :puppet

    confine do
      find_package('puppetserver')
    end
  end

  def config_files
    [
      '/etc/puppet',
      '/etc/puppetlabs',
      '/opt/puppetlabs/puppet/cache/foreman_cache_data',
      '/var/lib/puppet/foreman_cache_data',
      '/opt/puppetlabs/puppet/ssl/',
      '/var/lib/puppet/ssl',
      '/var/lib/puppet'
    ]
  end
end
