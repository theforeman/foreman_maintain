class Features::Satellite < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Downstream
  include ForemanMaintain::Concerns::Versions

  metadata do
    label :satellite

    confine do
      package_manager.installed?(['satellite'])
    end
  end

  def target_version
    '6.16'
  end

  def current_version
    @current_version ||= package_version(package_name) || version_from_source
  end

  def package_name
    'satellite'
  end

  def module_name
    'satellite'
  end

  private

  def version_from_source
    version(File.read('/usr/share/foreman/lib/satellite/version.rb')[/6\.\d\.\d/])
  end
end
