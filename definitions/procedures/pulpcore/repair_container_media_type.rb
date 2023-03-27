module Procedures::Pulpcore
  class RepairContainerMediaType < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemService

    metadata do
      description 'Repair container media type in the pulpcore db'
      for_feature :pulpcore
    end

    def run
      with_spinner('Repairing container media type in the pulpcore db') do |spinner|
        necessary_services = feature(:pulpcore_database).services

        feature(:service).handle_services(spinner, 'start', :only => necessary_services)

        spinner.update('Repairing container media type')
        execute!('PULP_SETTINGS=/etc/pulp/settings.py '\
                 'DJANGO_SETTINGS_MODULE=pulpcore.app.settings '\
                 'pulpcore-manager container-repair-media-type')
      end
    end
  end
end
