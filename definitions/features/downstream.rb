class Features::Downstream < ForemanMaintain::Feature
  metadata do
    label :downstream

    confine do
      downstream_installation?
    end
  end

  def less_than_version?(version)
    Gem::Version.new(current_version) < Gem::Version.new(version)
  end

  def at_least_version?(version)
    Gem::Version.new(current_version) >= Gem::Version.new(version)
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

  def absent_repos(version)
    all_repo_lines = execute(%(LANG=en_US.utf-8 subscription-manager repos --list 2>&1 | ) +
                              %(grep '^Repo ID:')).split("\n")
    all_repos = all_repo_lines.map { |line| line.split(/\s+/).last }
    repos_required = rh_repos(version)
    repos_found = repos_required & all_repos
    repos_required - repos_found
  end

  def rhsm_refresh
    execute!(%(subscription-manager refresh))
  end

  def subscribed_using_activation_key?
    ENV['EXTERNAL_SAT_ACTIVATION_KEY'] && ENV['EXTERNAL_SAT_ORG']
  end

  private

  def rh_repos(sat_version)
    sat_version = version(sat_version)
    rh_version_major = ForemanMaintain::Utils::Facter.os_major_release

    rh_repos = main_rh_repos(rh_version_major)

    rh_repos.concat(sat_and_tools_repos(rh_version_major, sat_version))

    if sat_version > version('6.3')
      rh_repos << ansible_repo(sat_version, rh_version_major)
    end

    if current_minor_version == '6.3' && sat_version.to_s != '6.4' && (
      feature(:puppet_server) && feature(:puppet_server).puppet_version.major == 4)
      rh_repos << "rhel-#{rh_version_major}-server-satellite-tools-6.3-puppet4-rpms"
    end

    rh_repos
  end

  def ansible_repo(sat_version, rh_version_major)
    if sat_version >= version('6.6')
      "rhel-#{rh_version_major}-server-ansible-2.8-rpms"
    elsif sat_version >= version('6.4')
      "rhel-#{rh_version_major}-server-ansible-2.6-rpms"
    end
  end

  def sat_and_tools_repos(rh_version_major, sat_version)
    sat_version_full = "#{sat_version.major}.#{sat_version.minor}"
    sat_repo_id = "rhel-#{rh_version_major}-server-satellite-#{sat_version_full}-rpms"
    sat_tools_repo_id = "rhel-#{rh_version_major}-server-satellite-tools-#{sat_version_full}-rpms"
    sat_maintenance_repo_id = "rhel-#{rh_version_major}-server-satellite-maintenance-6-rpms"

    # Override to use Beta repositories for sat version until GA
    if ENV['FOREMAN_MAINTAIN_USE_BETA'] == '1'
      sat_repo_id = "rhel-server-#{rh_version_major}-satellite-6-beta-rpms"
      sat_tools_repo_id = "rhel-#{rh_version_major}-server-satellite-tools-6-beta-rpms"
      sat_maintenance_repo_id = "rhel-#{rh_version_major}-server-satellite-maintenance-6-beta-rpms"
    end

    [sat_repo_id, sat_tools_repo_id, sat_maintenance_repo_id]
  end

  def main_rh_repos(rh_version_major)
    ["rhel-#{rh_version_major}-server-rpms",
     "rhel-server-rhscl-#{rh_version_major}-rpms"]
  end

  def version_from_source
    version(File.read('/usr/share/foreman/lib/satellite/version.rb')[/6\.\d\.\d/])
  end
end
