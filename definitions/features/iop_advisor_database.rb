class Features::IopAdvisorDatabase < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :iop_advisor_database

    confine do
      File.exist?('/etc/containers/networks/iop-core-network.json') ||
        File.exist?('/etc/containers/systemd/iop-core.network')
    end
  end

  def configuration
    @configuration || load_configuration
  end

  def services
    [
      system_service('postgresql', 10, :component => 'iop',
        :db_feature => feature(:iop_advisor_database)),
    ]
  end

  private

  def load_configuration
    podman_command = "podman exec iop-service-advisor-api bash -c 'env |grep DB_'"
    podman_result = execute!(podman_command, merge_stderr: false).lines.map do |l|
      l.strip.split('=')
    end.to_h

    db_host = if podman_result['ADVISOR_DB_HOST'].start_with?('/var/run/postgresql')
                'localhost'
              else
                podman_result['ADVISOR_DB_HOST']
              end
    @configuration = {
      'host' => db_host,
      'port' => podman_result['ADVISOR_DB_PORT'],
      'database' => podman_result['ADVISOR_DB_NAME'],
      'password' => podman_result['ADVISOR_DB_PASSWORD'],
      'username' => podman_result['ADVISOR_DB_USER'],
    }
  end
end
