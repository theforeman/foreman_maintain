require 'foreman_maintain/utils/service/systemd'

class Features::Pulp3 < ForemanMaintain::Feature
  metadata do
    label :pulp3

    confine do
      ForemanMaintain::Utils::Service::Systemd.new('pulpcore-api', 0).exist?
    end
  end

  def services
    [
      system_service('pulpcore-api', 10),
      system_service('pulpcore-content', 10),
      system_service('pulpcore-resource-manager', 10),
      system_service('pulpcore-worker@*', 20, :all => true),
      system_service('redis', 30),
      system_service('httpd', 30)
    ]
  end
end
