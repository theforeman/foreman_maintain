class Features::UpstreamRepositories < ForemanMaintain::Feature
  metadata do
    label :upstream_repositories

    confine do
      !feature(:instance).downstream?
    end
  end

  VERSION_MAPPING = {
    '3.16' => '2.1',
    '3.15' => '2.0',
    '3.14' => '1.24'
  }.freeze

  def setup_repositories(version)
    if feature(:katello)
      major_or_minor_repo_update(feature(:katello), version)
      version = VERSION_MAPPING[version]
    end
    major_or_minor_repo_update(feature(:foreman_server), version)
  end

  def major_or_minor_repo_update(feature, version)
    if feature.current_version == version
      feature(feature).update_repo(version)
    else
      package_manager.update(feature.repos_rpm(version, os_major_release), :assumeyes => true)
    end
    package_manager.clean_cache
  end

  def available?(version)
    if feature(:katello)
      repos_url = feature(:katello).repos_rpm(version, os_major_release)
      package_manager.link_valid?(repos_url)
      version = VERSION_MAPPING[version]
    end
    repos_url = feature(:foreman_server).repos_rpm(version, os_major_release)
    package_manager.link_valid?(repos_url)
  end

  def os_major_release
    @os_major_release ||= ForemanMaintain::Utils::Facter.os_major_release
  end
end
