class Features::Katello < ForemanMaintain::Feature
  metadata do
    label :katello

    confine do
      find_package('katello')
    end
  end

  KATELLO_RELEASE_PACKAGE = 'katello-repos'.freeze

  def data_dirs
    @dirs ||= ['/var/lib/pulp', '/var/lib/mongodb', '/var/lib/pgsql']
  end

  def current_version
    @current_version ||= rpm_version('katello')
  end

  def services
    [
      system_service('elasticsearch', 30)
    ]
  end

  # rubocop:disable  Metrics/MethodLength
  def config_files
    configs = [
      '/etc/pki/katello',
      '/etc/pki/katello-certs-tools',
      '/etc/pki/ca-trust',
      '/root/ssl-build',
      '/etc/candlepin',
      '/etc/sysconfig/tomcat*',
      '/etc/tomcat*',
      '/var/lib/candlepin',
      '/usr/share/foreman/bundler.d/katello.rb',
      '/etc/qpid',
      '/etc/qpid-dispatch',
      '/var/lib/qpidd',
      '/etc/qpid-dispatch'
    ]

    if installer_scenario_answers['certs']
      configs += [
        installer_scenario_answers['certs']['server_cert'],
        installer_scenario_answers['certs']['server_key'],
        installer_scenario_answers['certs']['server_cert_req'],
        installer_scenario_answers['certs']['server_ca_cert']
      ].compact
    end

    configs
  end
  # rubocop:enable  Metrics/MethodLength

  def config_files_exclude_for_online
    [
      '/var/lib/qpidd',
      '/var/lib/candlepin/activemq-artemis'
    ]
  end

  def repos_rpm(version)
    "https://fedorapeople.org/groups/katello/releases/yum/#{version}/katello"\
    "/el#{feature(:instance).os_major_release}/x86_64/#{KATELLO_RELEASE_PACKAGE}-latest.rpm"
  end

  def update_repo(version)
    repos_rpm = repos_rpm(version, feature(:instance).os_major_release)
    package_manager.update_or_install(KATELLO_RELEASE_PACKAGE, repos_rpm, :assumeyes => true)
  end

  private

  def installer_scenario_answers
    feature(:installer).answers
  end
end
