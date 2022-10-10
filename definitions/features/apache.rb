class Features::Apache < ForemanMaintain::Feature
  metadata do
    label :apache

    confine do
      find_package(package_name)
    end
  end

  def services
    [
      system_service(self.class.package_name, 30),
    ]
  end

  def config_files
    ["/etc/#{self.class.package_name}"]
  end

  class << self
    def package_name
      if debian?
        'apache2'
      else
        'httpd'
      end
    end
  end
end
