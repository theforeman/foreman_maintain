module Procedures::Pulpcore
  class Migrate < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemService

    metadata do
      description 'Migrate pulpcore db'
      for_feature :pulpcore
    end

    def run
      with_spinner('Migrating pulpcore') do |spinner|
        necessary_services = feature(:pulpcore_database).services
        pulp_services = feature(:pulpcore).services

        feature(:service).handle_services(spinner, 'start', :only => necessary_services)
        feature(:service).handle_services(spinner, 'stop', :only => pulp_services)

        spinner.update('Migrating pulpcore database')
        execute!('sudo PULP_SETTINGS=/etc/pulp/settings.py '\
          'DJANGO_SETTINGS_MODULE=pulpcore.app.settings '\
          'python3-django-admin migrate --noinput')
      end
    end
  end
end
