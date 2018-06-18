class Features::Katello < ForemanMaintain::Feature
  MIN_MEM = 7_900_000
  DISPLAY_MEM = 8

  metadata do
    label :katello

    confine do
      find_package('katello')
    end
  end

  def min_mem
    MIN_MEM
  end

  def display_mem
    DISPLAY_MEM
  end

  def data_dirs
    @dirs ||= ['/var/lib/pulp', '/var/lib/mongodb', '/var/lib/pgsql']
  end

  def current_version
    @current_version ||= rpm_version('katello')
  end

  def services
    {
      'qpidd'                    => 10,
      'qdrouterd'                => 10,
      'goferd'                   => 30,
      'elasticsearch'            => 30
    }
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
      '/usr/share/foreman/bundler.d/katello.rb'
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

  private

  def installer_scenario_answers
    feature(:installer).answers
  end
end
