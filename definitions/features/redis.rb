class Features::Redis < ForemanMaintain::Feature
  metadata do
    label :redis

    confine do
      # Luckily, the service name is the same as the package providing it
      server? && find_package(service_name)
    end
  end

  def services
    [system_service(self.class.service_name, 10)]
  end

  def config_files
    %w[redis redis.conf].map { |config| File.join(self.class.etc_prefix, config) }
  end

  class << self
    SCL_NAME = 'rh-redis5'.freeze

    def etc_prefix
      "/etc/opt/rh/#{SCL_NAME}"
    end

    def scl_prefix
      "#{SCL_NAME}-"
    end

    def service_name
      "#{scl_prefix}redis"
    end
  end
end
