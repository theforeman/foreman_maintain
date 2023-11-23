module Procedures::MaintenanceMode
  class IsEnabled < ForemanMaintain::Procedure
    metadata do
      description 'Showing status code for maintenance_mode'
      advanced_run false
      confine do
        feature(:nftables) || feature(:iptables)
      end
    end

    attr_reader :status_code

    def run
      @status_code = feature(:instance).firewall.maintenance_mode_status? ? 0 : 1
      puts "Maintenance mode is #{(@status_code == 1) ? 'Off' : 'On'}"
    end
  end
end
