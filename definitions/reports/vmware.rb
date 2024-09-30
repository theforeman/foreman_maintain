module Checks
  module Report
    class Vmware < ForemanMaintain::Report
      metadata do
        description 'Check if vmware compute resource is used'
      end

      def run
        count = sql_count("compute_resources WHERE type = 'Foreman::Model::Vmware'")
        self.data = { "compute_resource_vmware_count": count }
      end
    end
  end
end
