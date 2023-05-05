module Procedures::Pulpcore
  class TrimRpmChangelogs < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemService

    metadata do
      description 'Trim RPM changelogs in the pulpcore db'
      for_feature :pulpcore
    end

    def run
      with_spinner('Trimming RPM changelogs in the pulpcore db') do |spinner|
        necessary_services = feature(:pulpcore_database).services

        feature(:service).handle_services(spinner, 'start', :only => necessary_services)

        spinner.update('Trimming RPM changelogs')
        execute!('PULP_SETTINGS=/etc/pulp/settings.py '\
          'runuser -u pulp -- pulpcore-manager rpm-trim-changelogs')
      end
    end
  end
end
