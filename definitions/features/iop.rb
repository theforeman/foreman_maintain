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
      '/var/lib/kafka',
      '/var/lib/vmaas',
    ]
  end

  def services
    [
      system_service('iop-core-gateway', 20),
      system_service('iop-core-host-inventory-migrate', 20),
      system_service('iop-core-host-inventory', 20),
      system_service('iop-core-host-inventory-web', 20),
      system_service('iop-core-ingress', 20),
      system_service('iop-core-kafka', 20),
      system_service('iop-core-puptoo', 20),
      system_service('iop-core-yuptoo', 20),
      system_service('iop-service-vmaas-reposcan', 20),
      system_service('iop-service-vmaas-webapp-go', 20),
    ]
  end
end
