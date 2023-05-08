module Procedures::Pulpcore
  class TrimRpmChangelogs < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemService
    include ForemanMaintain::Concerns::PulpCommon

    metadata do
      description 'Trim RPM changelogs in the pulpcore db'
      for_feature :pulpcore
    end

    def run
      with_spinner('Trimming RPM changelogs in the pulpcore db') do |spinner|
        necessary_services = feature(:pulpcore_database).services

        feature(:service).handle_services(spinner, 'start', :only => necessary_services)

        spinner.update('Trimming RPM changelogs')
        execute!(pulpcore_manager('rpm-trim-changelogs'))
      end
    end
  end
end
