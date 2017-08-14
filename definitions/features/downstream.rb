class Features::Downstream < ForemanMaintain::Feature
  metadata do
    label :downstream

    confine do
      downstream_installation?
    end
  end

  def current_version
    @current_version ||= rpm_version('satellite') || version_from_source
  end

  def current_minor_version
    current_version.to_s[/^\d+\.\d+/]
  end

  def setup_repositories(version)
    activation_key = ENV['EXTERNAL_SAT_ACTIVATION_KEY']
    org = ENV['EXTERNAL_SAT_ORG']
    if activation_key
      org_options = org ? %(--org #{shellescape(org)}) : ''
      execute!(%(subscription-manager register #{org_options}\
                  --activationkey #{shellescape(activation_key)} --force))
    else
      execute!(%(subscription-manager repos --disable '*'))
      enable_options = rh_repos(version).map { |r| "--enable=#{r}" }.join(' ')
      execute!(%(subscription-manager repos #{enable_options}))
    end
  end

  private

  def rh_repos(sat_version)
    sat_version = version(sat_version)
    ["rhel-#{rh_version.major}-server-rpms",
     "rhel-#{rh_version.major}-rhscl-#{rh_version.major}-rpms",
     "rhel-#{rh_version.major}-server-satellite-#{sat_version.major}.#{sat_version.minor}-rpms"]
  end

  def rh_version
    return @rh_version if defined? @rh_version
    release_package = execute!('rpm -qf /etc/redhat-release')
    @rh_version = rpm_version(release_package, 'RELEASE')
  end

  def version_from_source
    version(File.read('/usr/share/foreman/lib/satellite/version.rb')[/6\.\d\.\d/])
  end
end
