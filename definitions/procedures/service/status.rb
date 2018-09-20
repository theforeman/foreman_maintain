require 'procedures/service/base'

module Procedures::Service
  class Status < Base
    metadata do
      description 'Get status of applicable services'
      Base.common_params(self)
      param :brief, 'Print only service name and status', :flag => true, :default => false
      param :failing, 'List only services which are not running', :flag => true, :default => false
    end

    def run
      format_options = { :brief => @brief, :failing => @failing }
      run_service_action('status', common_options.merge(format_options))
    end
  end
end
