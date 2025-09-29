class Features::IopVmaasDatabase < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :iop_vmaas_database

    confine do
      feature(:iop)
    end
  end

  def configuration
    @configuration || load_configuration
  end

  def services
    [
      system_service('postgresql', 10, :component => 'iop',
        :db_feature => feature(:iop_vmaas_database)),
    ]
  end

  private

  # rubocop:disable Metrics/MethodLength
  def load_configuration
    podman_command = "podman exec iop-service-vmaas-reposcan bash -c 'env |grep POSTGRESQL_'"
    podman_result = begin
      execute!(podman_command, merge_stderr: false).lines.map do |l|
        l.strip.split('=')
      end.to_h
    rescue ForemanMaintain::Error::ExecutionError
      {}
    end

    db_host = if podman_result['POSTGRESQL_HOST'].nil? ||
                 podman_result['POSTGRESQL_HOST'].start_with?('/var/run/postgresql')
                'localhost'
              else
                podman_result['POSTGRESQL_HOST']
              end
    @configuration = {
      'host' => db_host,
      'port' => podman_result['POSTGRESQL_PORT'],
      'database' => podman_result['POSTGRESQL_DATABASE'],
      'password' => podman_result['POSTGRESQL_PASSWORD'],
      'username' => podman_result['POSTGRESQL_USER'],
    }
  end
  # rubocop:enable Metrics/MethodLength
end
