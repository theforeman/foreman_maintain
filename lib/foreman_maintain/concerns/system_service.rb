module ForemanMaintain
  module Concerns
    module SystemService
      def system_service(name, priority, options = {})
        ForemanMaintain::Utils.system_service(name, priority, options)
      end
    end
  end
end
