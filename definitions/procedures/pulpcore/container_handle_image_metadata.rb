module Procedures::Pulpcore
  class ContainerHandleImageMetadata < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemService
    include ForemanMaintain::Concerns::PulpCommon

    metadata do
      description 'Initialize and expose container image metadata in the pulpcore db'
      for_feature :pulpcore
    end

    def run
      with_spinner('Initialize and expose container image metadata in the pulpcore db') do |spinner|
        necessary_services = feature(:pulpcore_database).services

        feature(:service).handle_services(spinner, 'start', :only => necessary_services)

        spinner.update('Adding image metadata to pulp. You can continue using the ' \
               'system normally while the task runs in the background.')
        execute!(pulpcore_manager('container-handle-image-data'))
        spinner.update('Adding image metadata to katello. You can continue using the ' \
               'system normally while the task runs in the background.')
        execute!('foreman-rake katello:import_container_manifest_labels')
      end
    end
  end
end
