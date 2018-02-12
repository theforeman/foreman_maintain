require 'procedures/service/base'

module Procedures::Service
  class Start < Base
    metadata do
      description 'Start applicable services'
      Base.common_params(self)
    end

    def run
      run_service_action('start', common_options)
    end
  end
end
