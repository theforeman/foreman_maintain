module ForemanMaintain
  module Features
    class ForemanService < ForemanMaintain::Feature
      metadata do
        confine do
          package_manager.installed?(['foreman-service']) && check_min_version('foreman', '2.1')
        end
      end

      def service
        system_service('foreman', 30)
      end
    end
  end
end
