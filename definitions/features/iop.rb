class Features::Iop < ForemanMaintain::Feature
  metadata do
    label :iop

    confine do
      File.exist?('/etc/containers/networks/iop-core-network.json') ||
        File.exist?('/etc/containers/systemd/iop-core.network')
    end
  end

  def config_files
    [
      '/var/lib/containers/storage/volumes/iop-core-kafka-data',
      '/var/lib/vmaas',
    ]
  end

  # rubocop:disable Metrics/MethodLength
  def services
    [
      system_service('iop-core-engine', 20),
      system_service('iop-core-gateway', 20),
      system_service('iop-core-host-inventory', 20),
      system_service('iop-core-host-inventory-api', 20),
      system_service('iop-core-host-inventory-migrate', 20),
      system_service('iop-core-ingress', 20),
      system_service('iop-core-kafka', 20),
      system_service('iop-core-puptoo', 20),
      system_service('iop-core-yuptoo', 20),
      system_service('iop-service-advisor-backend-api', 20),
      system_service('iop-service-advisor-backend-service', 20),
      system_service('iop-service-remediations-api', 20),
      system_service('iop-service-vmaas-reposcan', 20),
      system_service('iop-service-vmaas-webapp-go', 20),
      system_service('iop-service-vuln-dbupgrade', 20),
      system_service('iop-service-vuln-evaluator-recalc', 20),
      system_service('iop-service-vuln-evaluator-upload', 20),
      system_service('iop-service-vuln-grouper', 20),
      system_service('iop-service-vuln-listener', 20),
      system_service('iop-service-vuln-manager', 20),
      system_service('iop-service-vuln-taskomatic', 20),
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def container_base
    if feature(:instance).downstream
      'registry.redhat.io/satellite'
    else
      'ghcr.io/redhatinsights'
    end
  end

  def container_name
    if feature(:instance).downstream
      'iop-advisor-engine-rhel9'
    else
      'iop-advisor-engine'
    end
  end

  def container_version
    if feature(:instance).downstream
      '6.17'
    else
      'latest'
    end
  end

  def container_image
    "#{container_base}/#{container_name}:#{container_version}"
  end
end
