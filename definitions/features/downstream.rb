class Features::Downstream < ForemanMaintain::Feature
  label :downstream

  confine do
    downstream_installation?
  end

  def current_version
    @current_version ||= rpm_version('satellite') || version_from_source
  end

  private

  def version_from_source
    version(File.read('/usr/share/foreman/lib/satellite/version.rb')[/6\.\d\.\d/])
  end
end
