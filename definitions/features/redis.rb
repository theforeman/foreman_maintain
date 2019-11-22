class Features::Redis < ForemanMaintain::Feature
  SCL_PREFIX = 'rh-redis5'.freeze
  SERVICE_NAME = "#{SCL_PREFIX}-redis".freeze

  metadata do
    label :redis

    confine do
      # Luckily, the service name is the same as the package providing it
      server? && find_package(SERVICE_NAME)
    end

    def services
      [system_service(SERVICE_NAME, 10)]
    end

    def config_files
      ["/etc/opt/rh/#{SCL_PREFIX}/redis",
       "/etc/opt/rh/#{SCL_PREFIX}/redis.conf"]
    end
  end
end
