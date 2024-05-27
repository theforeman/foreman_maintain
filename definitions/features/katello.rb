class Features::Katello < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Versions

  metadata do
    label :katello

    confine do
      find_package('katello')
    end
  end

  def data_dirs
    @dirs ||= ['/var/lib/pulp', '/var/lib/pgsql']
  end

  def current_version
    @current_version ||= package_version('katello')
  end

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
    ]

    if installer_scenario_answers['certs']
      configs += [
        installer_scenario_answers['certs']['server_cert'],
        installer_scenario_answers['certs']['server_key'],
        installer_scenario_answers['certs']['server_cert_req'],
        installer_scenario_answers['certs']['server_ca_cert'],
      ].compact
    end

    configs
  end

  def config_files_exclude_for_online
    [
      '/var/lib/candlepin/activemq-artemis',
    ]
  end

  private

  def installer_scenario_answers
    feature(:installer).answers
  end
end
