module Reports
  class Virtwho < ForemanMaintain::Report
    metadata do
      description 'Check if virt-who is being used and what hypervisor types are present'
    end

    HYPERVISOR_TYPES = %w[ahv esx fakevirt hyperv kubevirt libvirtd].freeze

    def run
      self.data = {}
      data_field('foreman_virt_who_configure_configurations_count') do
        sql_count('foreman_virt_who_configure_configs')
      end

      HYPERVISOR_TYPES.each do |type|
        data["foreman_virt_who_configure_#{type}_count"] =
          sql_count("foreman_virt_who_configure_configs WHERE hypervisor_type = '#{type}'")
      end
    end
  end
end
