require 'procedures/service/base'

module Procedures::Service
  class Status < Base
    metadata do
      description 'Get status of applicable services'
      Base.common_params(self)
    end

    def run
      run_service_action('status', common_options)
    end
  end
end
