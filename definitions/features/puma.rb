module ForemanMaintain
  module Features
    class Puma < ForemanMaintain::Feature
      metadata do
        label :puma
        confine do
          package_manager.installed?(['foreman-service']) && check_min_version('foreman', '2.1')
        end
      end

      def services
        [
          system_service('foreman', 30)
        ]
      end
    end
  end
end
