class Features::Apache < ForemanMaintain::Feature
  metadata do
    label :apache

    confine do
      find_package('httpd')
    end
  end

  def services
    [
      system_service('httpd', 30)
    ]
  end

  def config_files
    ['/etc/httpd']
  end
end
