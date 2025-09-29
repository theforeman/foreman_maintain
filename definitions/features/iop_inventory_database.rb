class Features::IopInventoryDatabase < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :iop_inventory_database

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
        :db_feature => feature(:iop_inventory_database)),
    ]
  end

  private

  # rubocop:disable Metrics/MethodLength
  def load_configuration
    podman_command = "podman exec iop-core-host-inventory bash -c 'env |grep INVENTORY_DB_'"
    podman_result = begin
      execute!(podman_command, merge_stderr: false).lines.map do |l|
        l.strip.split('=')
      end.to_h
    rescue ForemanMaintain::Error::ExecutionError
      {}
    end

    db_host = if podman_result['INVENTORY_DB_HOST'].nil? ||
                 podman_result['INVENTORY_DB_HOST'].start_with?('/var/run/postgresql')
                'localhost'
              else
                podman_result['INVENTORY_DB_HOST']
              end
    @configuration = {
      'host' => db_host,
      'port' => podman_result['INVENTORY_DB_PORT'],
      'database' => podman_result['INVENTORY_DB_NAME'],
      'password' => podman_result['INVENTORY_DB_PASS'],
      'username' => podman_result['INVENTORY_DB_USER'],
    }
  end
  # rubocop:enable Metrics/MethodLength
end
