module Procedures::MaintenanceMode
  class IsEnabled < ForemanMaintain::Procedure
    metadata do
      description 'Showing status code for maintenance_mode'
      for_feature :iptables
      advanced_run false
    end

    attr_reader :status_code

    def run
      @status_code = feature(:iptables).maintenance_mode_chain_exist? ? 1 : 0
      puts "Maintenance mode is #{@status_code == 0 ? 'Off' : 'On'}"
    end
  end
end
