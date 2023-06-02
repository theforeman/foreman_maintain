require 'foreman_maintain/utils/service/systemd'

class Features::Pulpcore < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::PulpCommon

  metadata do
    label :pulpcore
  end

  def services
    redis_services = feature(:redis) ? feature(:redis).services : []

    self.class.pulpcore_common_services + configured_workers +
      redis_services
  end

  def configured_workers
    names = Dir['/etc/systemd/system/multi-user.target.wants/pulpcore-worker@*.service']
    names = names.map { |f| File.basename(f) }
    names.map do |name|
      system_service(name, 20, :skip_enablement => true,
                               :instance_parent_unit => 'pulpcore-worker@')
    end
  end

  def config_files
    [
      '/etc/pulp/settings.py',
      '/etc/pulp/certs/database_fields.symmetric.key',
    ]
  end

  def self.pulpcore_common_services
    [
      ForemanMaintain::Utils.system_service('pulpcore-api', 10, :socket => 'pulpcore-api'),
      ForemanMaintain::Utils.system_service('pulpcore-content', 10, :socket => 'pulpcore-content'),
    ]
  end
end
