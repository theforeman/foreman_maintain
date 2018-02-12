require 'procedures/service/base'

module Procedures::Service
  class Disable < Base
    metadata do
      description 'Disable applicable services'
      Base.common_params(self)
    end

    def run
      run_service_action('disable', common_options)
    end
  end
end
