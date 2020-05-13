require 'procedures/service/base'

module Procedures::Service
  class Stop < Base
    metadata do
      description 'Stop applicable services'
      Base.common_params(self)
    end

    def run
      run_service_action('stop', common_options.merge(:include_sockets => true))
    end
  end
end
