class Features::Satellite < ForemanMaintain::Feature
  metadata do
    label :satellite

    confine do
      satellite_installation?
    end
  end

  def current_version
    @current_version ||= rpm_version('satellite') || version_from_source
  end

  private

  def version_from_source
    version(File.read('/usr/share/foreman/lib/satellite/version.rb')[/6\.\d\.\d/])
  end
end
