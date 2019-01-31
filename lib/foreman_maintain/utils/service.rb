require 'foreman_maintain/utils/service/abstract'
require 'foreman_maintain/utils/service/systemd'
require 'foreman_maintain/utils/service/remote_db'

module ForemanMaintain::Utils
  def self.system_service(name, priority, options = {})
    db_feature = options.fetch(:db_feature, nil)
    if db_feature && db_feature.respond_to?(:local?) && !db_feature.local?
      Service::RemoteDB.new(name, priority, options)
    else
      Service::Systemd.new(name, priority, options)
    end
  end

  def self.valid_sys_service?(service)
    service.class < Service::Abstract
  end
end
