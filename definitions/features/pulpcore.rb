require 'foreman_maintain/utils/service/systemd'

class Features::Pulpcore < ForemanMaintain::Feature
  metadata do
    label :pulpcore

    confine do
      ForemanMaintain::Utils::Service::Systemd.new('pulpcore-api', 0).exist? &&
        ForemanMaintain::Utils::Service::Systemd.new('pulpcore-api', 0).enabled?
    end
  end

  def services
    pulpcore_common_services + [
      system_service('pulpcore-worker@*', 20, :all => true, :skip_enablement => true),
      system_service('httpd', 30)
    ]
  end

  def pulpcore_migration_services
    pulpcore_common_services + [
      system_service('pulpcore-worker@1', 20),
      system_service('pulpcore-worker@2', 20),
      system_service('pulpcore-worker@3', 20),
      system_service('pulpcore-worker@4', 20)
    ]
  end

  def config_files
    [
      '/etc/pulp/settings.py'
    ]
  end

  private

  def pulpcore_common_services
    [
      system_service('rh-redis5-redis', 5),
      system_service('pulpcore-api', 10),
      system_service('pulpcore-content', 10),
      system_service('pulpcore-resource-manager', 10)
    ]
  end
end
