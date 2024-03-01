module Checks
  module Report
    class CheckVmwareUsage < ForemanMaintain::Check
      metadata do
        description 'Check if vmware compute resource is used'
        tags :report
      end

      def run
        count = feature(:foreman_database).query(self.class.query)
        self.data = { "compute_resource_vmware_count": count.first['count'].to_i }
      end


      def self.query
        <<-SQL
          SELECT COUNT(*) FROM compute_resources WHERE type = 'Foreman::Model::Vmware'
        SQL
      end
    end
  end
end
