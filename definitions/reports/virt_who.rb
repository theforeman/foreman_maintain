module Checks
  module Report
    class Virtwho < ForemanMaintain::Report
      metadata do
        description 'Check if virt-who is being used and what hypervisor types are present'
      end

      HYPERVISOR_TYPES = %w[ahv esx fakevirt hyperv kubevirt libvirtd].freeze

      def run
        self.data = {}
        data['foreman_virt_who_configure_configurations_count'] =
          sql_count('foreman_virt_who_configure_configs')

        HYPERVISOR_TYPES.each do |type|
          data["foreman_virt_who_configure_#{type}_count"] =
            sql_count("foreman_virt_who_configure_configs WHERE hypervisor_type = '#{type}'")
        end
      end
    end
  end
end
