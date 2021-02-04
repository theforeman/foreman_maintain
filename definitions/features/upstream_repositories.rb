class Features::UpstreamRepositories < ForemanMaintain::Feature
  metadata do
    label :upstream_repositories

    confine do
      !feature(:instance).downstream?
    end
  end
  attr_accessor :version

  VERSION_MAPPING = {
    '3.16' => '2.1',
    '3.15' => '2.0',
    '3.14' => '1.24'
  }.freeze

  def setup_repositories(version)
    @version = version
    if feature(:katello)
      major_or_minor_repo_update(feature(:katello))
      @version = VERSION_MAPPING[version]
      major_or_minor_repo_update(feature(:foreman_server))
    elsif feature(:foreman_server)
      major_or_minor_repo_update(feature(:foreman_server))
    end
  end

  def major_or_minor_repo_update(feature)
    if feature.current_version == @version
      update_repos(feature)
    else
      package_manager.update(repo_rpm.fetch(feature.label), :assumeyes => true)
    end
    package_manager.clean_cache
  end

  def available?(version)
    @version = version
    if feature(:katello)
      package_manager.link_valid?(repo_rpm.fetch(feature.label))
      @version = VERSION_MAPPING[version]
    end
    package_manager.link_valid?(repo_rpm.fetch(feature.label))
  end

  def update_repos(feature)
    package_manager.update_or_install(feature::RELEASE_PACKAGE,
                                      repo_rpm.fetch(feature.label), :assumeyes => true)
    if feature(:foreman)
      package_manager.update('centos-release-scl-rh', :assumeyes => true)
    end
  end

  def repo_rpm
    @repo_rpm ||=
      { :foreman => "#{feature(:foreman)::EL_REPO_URL}#{@version}"\
      "/el#{feature(:instance).os_major_release}/x86_64/#{feature(:foreman)::RELEASE_PACKAGE}.rpm",
        :katello => "#{feature(:katello)::REPO_URL}#{@version}/katello"\
      "/el#{feature(:instance).os_major_release}/x86_64/"\
      "#{feature(:katello)::RELEASE_PACKAGE}-latest.rpm" }
  end
end
