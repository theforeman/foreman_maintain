module Procedures::Pulpcore
  class RpmDatarepair < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::PulpCommon

    metadata do
      description 'Run Pulp RPM data repair commands'
      for_feature :pulpcore
    end

    def run
      # Fix package_signing_fingerprint empty strings (SAT-42632 / PULP-1263)
      # Do not fail if unavailable
      with_spinner('Running pulpcore-manager rpm-datarepair 4007') do |spinner|
        exit_status, output = execute_with_status(pulpcore_manager('rpm-datarepair 4007'))
        if exit_status != 0 && output.include?("Unknown issue: '4007'")
          spinner.update('Skipped pulpcore-manager rpm-datarepair 4007, not available')
        elsif exit_status != 0
          fail!(output)
        end
      end
    end
  end
end
