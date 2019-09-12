class Features::ForemanProxy < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::BaseForemanProxy

  metadata do
    label :foreman_proxy
    confine do
      find_package('foreman-proxy') && !feature(:instance).downstream?
    end
  end

  def internal?
    !!feature(:foreman_server)
  end

  def external?
    !feature(:foreman_server)
  end
end
