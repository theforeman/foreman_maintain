class Features::ContainerGatewayDatabase < ForemanMaintain::Feature
  CONTAINER_GATEWAY_DB_CONFIG = '/etc/foreman-proxy/settings.d/container_gateway.yml'.freeze

  include ForemanMaintain::Concerns::BaseDatabase
  include ForemanMaintain::Concerns::DirectoryMarker

  metadata do
    label :container_gateway_database

    confine do
      file_nonzero?(CONTAINER_GATEWAY_DB_CONFIG)
    end
  end

  def configuration
    @configuration || load_configuration
  end

  def services
    [
      system_service('postgresql', 10, :component => 'container_gateway',
        :db_feature => feature(:container_gateway_database)),
    ]
  end

  private

  def load_configuration
    config = YAML.load(File.read(CONTAINER_GATEWAY_DB_CONFIG))
    @configuration = {}
    connection_string = config[:db_connection_string]
    if connection_string
      uri = URI.parse(connection_string)
      @configuration['connection_string'] = connection_string
      @configuration['database'] = uri.path.delete_prefix('/')
    end
    @configuration
  end
end
