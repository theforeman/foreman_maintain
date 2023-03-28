class Features::Redis < ForemanMaintain::Feature
  metadata do
    label :redis

    confine do
      # Luckily, the service name is the same as the package providing it
      find_package(service_name)
    end
  end

  def services
    [system_service(self.class.service_name, 5)]
  end

  def config_files
    %w[redis redis.conf].map { |config| File.join('/etc', config) }
  end

  class << self
    def service_name
      'redis'
    end
  end
end
