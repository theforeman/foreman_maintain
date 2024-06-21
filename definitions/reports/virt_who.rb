module Checks
    module Report
      class Virtwho < ForemanMaintain::Report
        metadata do
          description 'Check if virt-who is being used and what hypervisor types are present'
        end
  
        def run
          count = sql_count("SELECT COUNT(*) FROM foreman_virt_who_configure_configs")
          hypervisor_types = feature(:foreman_database).query("SELECT hypervisor_type FROM foreman_virt_who_configure_configs")
          self.data = { "virt_who_configurations": count,
                        "Hypervisor types": hypervisor_types
                      }
        end
      end
    end
  end
  