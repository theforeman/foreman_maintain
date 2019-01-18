module ForemanMaintain
  module Concerns
    module SystemService
      def system_service(name, priority = 50, options = {})
        ForemanMaintain::Utils.system_service(name, priority, options)
      end

      def valid_sys_service?(service)
        ForemanMaintain::Utils.valid_sys_service?(service)
      end
    end
  end
end
