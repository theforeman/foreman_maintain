module Checks
  module Report
    class Instance < ForemanMaintain::Report
      metadata do
        description 'Report information about the instance itself'
      end

      def run
        self.data = {
          'instance_uuid' => YAML.safe_load(sql_setting('instance_id')),
        }
      end
    end
  end
end
