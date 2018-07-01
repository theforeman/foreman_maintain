require 'procedures/maintenance_mode/base'

module Procedures::MaintenanceMode
  class IsEnabled < Base
    metadata do
      description 'Showing status code for maintenance_mode'
      advanced_run false
    end

    attr_reader :status_code

    def run
      fetch_status_code
    end

    private

    def fetch_status_code
      @status_code = 0 if status_values.empty?
      @status_code = 1 if status_values.length > 1
      @status_code = (status_values.first == 0 ? 0 : 1)
    end
  end
end
