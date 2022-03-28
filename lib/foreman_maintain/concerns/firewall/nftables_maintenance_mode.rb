module ForemanMaintain
  module Concerns
    module Firewall
      module NftablesMaintenanceMode
        def disable_maintenance_mode
          delete_table if table_exist?
        end

        def enable_maintenance_mode
          unless table_exist?
            add_table
            add_chain(:chain_options => nftables_chain_options)
            add_rule(rule: nftables_rule)
          end
        end

        def maintenance_mode_status?
          table_exist?
        end

        def nftables_chain_options
          '{type filter hook input priority 0\\;}'
        end

        def nftables_rule
          'tcp dport https reject'
        end

        def status_for_maintenance_mode
          if table_exist?
            ['Nftables table: present', []]
          else
            ['Nftables table: absent', []]
          end
        end
      end
    end
  end
end
