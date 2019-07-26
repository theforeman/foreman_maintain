class Features::Satellite < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Downstream

  metadata do
    label :satellite

    confine do
      feature(:package_manager).satellite_installed?
    end
  end

  def current_version
    @current_version ||= rpm_version(package_name) || version_from_source
  end

  private

  def package_name
    feature(:package_manager).satellite_package
  end

  def version_from_source
    version(File.read('/usr/share/foreman/lib/satellite/version.rb')[/6\.\d\.\d/])
  end
end
