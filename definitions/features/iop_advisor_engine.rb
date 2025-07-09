class Features::IopAdvisorEngine < ForemanMaintain::Feature
  metadata do
    label :iop_advisor_engine

    confine do
      server? && ForemanMaintain::Utils::Service::Systemd.new('iop-advisor-engine', 30).exist?
    end
  end

  def services
    [
      system_service('iop-advisor-engine', 30),
    ]
  end

  def container_image
    if feature(:instance).downstream
      'registry.redhat.io/satellite/iop-advisor-engine-rhel9:6.17'
    else
      'ghcr.io/redhatinsights/iop-advisor-engine:latest'
    end
  end
end
