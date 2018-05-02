module Procedures::Pulp
  class Migrate < ForemanMaintain::Procedure
    metadata do
      description 'Migrate pulp db'
      for_feature :pulp
    end

    def run
      with_spinner('Migrating pulp') do |spinner|
        necessary_services = feature(:mongo).services.keys + ['qpidd']
        pulp_services = %w[pulp_celerybeat pulp_workers pulp_resource_manager]

        feature(:service).handle_services(spinner, 'start', :only => necessary_services)
        feature(:service).handle_services(spinner, 'stop', :only => pulp_services)

        spinner.update('Migrating pulp database')
        execute!('su - apache -s /bin/bash -c pulp-manage-db')
      end
    end
  end
end
