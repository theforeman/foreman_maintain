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
      execute!(%(subscription-manager refresh))
      execute!(%(subscription-manager repos --disable '*'))
      enable_options = rh_repos(version).map { |r| "--enable=#{r}" }.join(' ')
      execute!(%(subscription-manager repos #{enable_options}))
    end
  end

  def absent_repos(version)
    execute!(%(subscription-manager refresh))
    all_repos = execute!(
      %('LANG=en_US.utf-8 subscription-manager repos --list | ') \
        %("awk -F':' '/Repo ID/{gsub(/ /, \"\", $2); print $2}'")
    ).split("\n")
    repos_required = rh_repos(version)
    repos_found = repos_required & all_repos
    repos_required - repos_found
  end

  private

  def rh_repos(sat_version)
    sat_version = version(sat_version)
    rh_version_major = execute!('facter operatingsystemmajrelease')
    sat_version_full = "#{sat_version.major}.#{sat_version.minor}"

    sat_repo_id = "rhel-#{rh_version_major}-server-satellite-#{sat_version_full}-rpms"
    sat_tools_repo_id = "rhel-#{rh_version_major}-server-satellite-tools-#{sat_version_full}-rpms"

    ["rhel-#{rh_version_major}-server-rpms",
     "rhel-server-rhscl-#{rh_version_major}-rpms",
     "rhel-#{rh_version_major}-server-satellite-maintenance-6-rpms",
     sat_tools_repo_id,
     sat_repo_id]
  end

  def version_from_source
    version(File.read('/usr/share/foreman/lib/satellite/version.rb')[/6\.\d\.\d/])
  end
end
