class Features::Capsule < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Downstream
  include ForemanMaintain::Concerns::BaseForemanProxy

  metadata do
    label :capsule

    confine do
      find_package('foreman-proxy') && feature(:instance).downstream?
    end
  end

  def internal?
    !!feature(:foreman_server)
  end

  def external?
    !feature(:foreman_server) &&
      feature(:installer) && feature(:installer).last_scenario.eql?('capsule')
  end

  def current_version
    @current_version ||= rpm_version(package_name)
  end

  private

  def package_name
    feature(:package_manager).capsule_package
  end
end
