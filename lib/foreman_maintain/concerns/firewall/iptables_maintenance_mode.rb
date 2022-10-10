module ForemanMaintain
  module Concerns
    module Firewall
      module IptablesMaintenanceMode
        def disable_maintenance_mode
          remove_chain(custom_chain_name)
        end

        def enable_maintenance_mode
          add_chain(custom_chain_name,
            ['-i lo -j ACCEPT', '-p tcp --dport 443 -j REJECT'])
        end

        def maintenance_mode_status?
          chain_exist?(custom_chain_name)
        end

        def status_for_maintenance_mode
          if maintenance_mode_status?
            ['Iptables chain: present', []]
          else
            ['Iptables chain: absent', []]
          end
        end
      end
    end
  end
end
