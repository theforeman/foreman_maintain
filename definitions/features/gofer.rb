class Features::Gofer < ForemanMaintain::Feature
  metadata do
    label :gofer

    confine do
      find_package('gofer') &&
        ForemanMaintain::Utils::Service::Systemd.new('goferd', 0).enabled?
    end
  end

  def services
    [
      system_service('goferd', 30),
    ]
  end
end
