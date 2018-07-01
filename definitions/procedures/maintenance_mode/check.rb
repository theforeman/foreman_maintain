require 'procedures/maintenance_mode/base'

module Procedures::MaintenanceMode
  class Check < Base
    metadata do
      description 'Check maintenance-mode status'
      advanced_run false
    end

    def run
      with_spinner('Checking maintenance-mode status') do |_spinner|
        info_string = "\nStatus of maintenance-mode: "
        info_string += construct_status_string
        puts info_string
      end
    end

    private

    def construct_status_string
      return 'Off' if status_values.empty?
      return 'Partially On' if status_values.length > 1
      (status_values.first == 0 ? 'Off' : 'On')
    end
  end
end
