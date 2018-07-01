module Procedures
  module MaintenanceMode
    class Base < ForemanMaintain::Procedure
      metadata do
        advanced_run false
      end
      attr_reader :status_by_each_feature

      def status_values
        @status_by_each_feature ||= fetch_each_feature_status
        @status_by_each_feature.values.compact.uniq
      end

      private

      def fetch_each_feature_status
        values = {}
        [:cron, :iptables, :sync_plans].each do |key_name|
          next unless feature(key_name)
          if feature(key_name).respond_to?(:maintenance_mode?)
            values[key_name] = feature(key_name).maintenance_mode?
          end
          if key_name == :cron
            cron_service = feature(:cron).services.key(5)
            values[key_name] = (feature(:service).find_service_status(cron_service) ? 0 : 1)
          end
        end
        values
      end
    end
  end
end
