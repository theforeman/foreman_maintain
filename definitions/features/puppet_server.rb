class Features::PuppetServer < ForemanMaintain::Feature
  metadata do
    label :puppet_server

    # We only check puppetserver and not puppet-server, as puppet-server
    # is a part of httpd and relies on httpd service to restart, therefore
    # not requiring a separate service to restart
    confine do
      find_package('puppetserver') || find_package('puppet')
    end
  end

  def services
    find_package('puppetserver') ? [system_service('puppetserver', 30)] : []
  end

  def puppet_version
    version(execute!('puppet --version'))
  end
end
