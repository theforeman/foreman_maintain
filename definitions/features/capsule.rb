require 'features/foreman_proxy'

class Features::Capsule < Features::ForemanProxy
  include ForemanMaintain::Concerns::Downstream

  metadata do
    label :capsule

    confine do
      # TODO: check on :super for confine
      find_package('foreman-proxy') && feature(:instance).downstream?
    end
  end

  def internal?
    server?
  end

  def external?
    !server? && feature(:installer) && feature(:installer).last_scenario.eql?('capsule')
  end

  def current_version
    @current_version ||= rpm_version(package_name)
  end

  private

  def package_name
    feature(:package_manager).capsule_package
  end
end
