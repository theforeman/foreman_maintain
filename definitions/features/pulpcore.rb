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
    self.class.pulpcore_common_services + configured_workers + [
      system_service('rh-redis5-redis', 5),
      system_service('httpd', 30)
    ]
  end

  def configured_workers
    names = Dir['/etc/systemd/system/multi-user.target.wants/pulpcore-worker@*.service']
    names = names.map { |f| File.basename(f) }
    names.map do |name|
      system_service(name, 20, :skip_enablement => true,
                               :instance_parent_unit => 'pulpcore-worker@')
    end
  end

  def self.pulpcore_migration_services
    pulpcore_common_services + [
      ForemanMaintain::Utils.system_service('pulpcore-worker@1', 20),
      ForemanMaintain::Utils.system_service('pulpcore-worker@2', 20),
      ForemanMaintain::Utils.system_service('pulpcore-worker@3', 20),
      ForemanMaintain::Utils.system_service('pulpcore-worker@4', 20)
    ]
  end

  def config_files
    [
      '/etc/pulp/settings.py'
    ]
  end

  def self.pulpcore_common_services
    common_services = [
      ForemanMaintain::Utils.system_service('pulpcore-api', 10, :socket => 'pulpcore-api'),
      ForemanMaintain::Utils.system_service('pulpcore-content', 10, :socket => 'pulpcore-content')
    ]
    common_services + pulpcore_resource_manager_service
  end

  def self.pulpcore_resource_manager_service
    # The pulpcore_resource_manager is only required on 3.14+
    # if the old tasking system is being used
    # The foreman-installer does not create unit file for this service,
    # if the new tasking system is being used
    if feature(:service).unit_file_available?('pulpcore-resource-manager.service')
      return [ForemanMaintain::Utils.system_service('pulpcore-resource-manager', 10)]
    end

    []
  end
end
