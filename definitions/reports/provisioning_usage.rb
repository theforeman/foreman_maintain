module Checks
  module Report
    class Provisioning < ForemanMaintain::Report
      metadata do
        description 'Count hosts that have been provisioned in the last 3 months.'
      end

      def run
        sql = "hosts WHERE managed = true AND created_at >= current_date - interval '3 months'"
        result = sql_count(sql)

        self.data = { managed_hosts_created_in_last_3_months: result }
      end
    end
  end
end
