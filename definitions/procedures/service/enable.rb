require 'procedures/service/base'

module Procedures::Service
  class Enable < Base
    metadata do
      description 'Enable applicable services'
      Base.common_params(self)
    end

    def run
      run_service_action('enable', common_options)
    end
  end
end
