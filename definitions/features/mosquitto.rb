class Features::Mosquitto < ForemanMaintain::Feature
  metadata do
    label :mosquitto

    confine do
      # Luckily, the service name is the same as the package providing it
      find_package(service_name)
    end
  end

  def services
    [system_service(self.class.service_name, 10)]
  end

  def config_files
    [self.class.etc_prefix]
  end

  class << self
    def etc_prefix
      '/etc/mosquitto'
    end

    def service_name
      'mosquitto'
    end
  end
end
