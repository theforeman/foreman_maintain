require 'procedures/service/base'

module Procedures::Service
  class Stop < Base
    metadata do
      description 'Stop applicable services'
      Base.common_params(self)
    end

    def run
      param_options = override_options
      run_service_action('stop', param_options)
    end

    def override_options
      param_options = common_options
      if foreman_socket_handling_required?
        param_options[key_to_override] << feature(:foreman_server).socket_name
      end
      param_options
    end

    private

    def key_to_override
      !@only.empty? && @only.include?('foreman') ? :only : :include
    end

    def foreman_socket_handling_required?
      ((@only.empty? && @exclude.empty?) || (!@only.empty? && @only.include?('foreman')) ||
        (!@exclude.empty? && !@exclude.include?('foreman'))
      ) && feature(:foreman_server) && feature(:foreman_server).socket_name
    end
  end
end
