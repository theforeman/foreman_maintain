class Features::Redis < ForemanMaintain::Feature
  SCL_NAME = 'rh-redis5'.freeze

  metadata do
    label :redis

    confine do
      # Luckily, the service name is the same as the package providing it
      server? && find_package(service_name)
    end
  end

  def services
    [system_service(service_name, 10)]
  end

  def config_files
    ["/etc/opt/rh/#{SCL_NAME}/redis",
     "/etc/opt/rh/#{SCL_NAME}/redis.conf"]
  end

  private

  def scl_prefix
    "#{SCL_NAME}-"
  end

  def service_name
    "#{scl_prefix}redis"
  end
end
