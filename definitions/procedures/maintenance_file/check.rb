module Procedures::MaintenanceFile
  class Check < ForemanMaintain::Procedure
    metadata do
      description 'Check maintenance_file'
      for_feature :maintenance_mode
      advanced_run false
    end

    def run
      check_for_maintenance_file
    end

    def exit_code_to_override
      @exit_code
    end

    private

    def check_for_maintenance_file
      info_string = "\nStatus of maintenance-mode: "
      if feature(:maintenance_mode).maintenance_file_present?
        info_string += 'ON'
        @exit_code = 1
      else
        info_string += 'OFF'
        @exit_code = 0
      end
      puts info_string
    end
  end
end
