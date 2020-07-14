class Features::PuppetServer < ForemanMaintain::Feature
  metadata do
    label :puppet_server

    confine do
      find_package('puppet-server') || find_package('puppetserver') || find_package('puppet')
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
      '/var/lib/puppet',
      '/usr/share/ruby/vendor_ruby/puppet/reports/foreman.rb',
      '/opt/puppetlabs/puppet/lib/ruby/vendor_ruby/puppet/reports/foreman.rb'
    ]
  end

  def services
    # We only check puppetserver and not puppet-server, as puppet-server
    # is a part of httpd and relies on httpd service to restart, therefore
    # not requiring a separate service to restart
    find_package('puppetserver') ? [system_service('puppetserver', 30)] : []
  end

  def puppet_version
    version(execute!("#{puppet_path} --version"))
  end

  def find_empty_cacert_request_files
    cmd_output = execute!("find #{cacert_requests_directory} -type f -size 0 | paste -d, -s")
    cmd_output.split(',')
  end

  def delete_empty_cacert_files
    execute!("find #{cacert_requests_directory} -type f -size 0 -delete")
  end

  def cacert_requests_directory
    "#{ca_directory_path}/requests"
  end

  def cacert_requests_dir_exists?
    File.directory?(cacert_requests_directory)
  end

  private

  def ca_directory_path
    "#{puppet_ssldir_path}/ca"
  end

  def puppet_ssldir_path
    execute!("#{puppet_path} config print ssldir")
  end

  def puppet_path
    '/opt/puppetlabs/bin/puppet'
  end
end
