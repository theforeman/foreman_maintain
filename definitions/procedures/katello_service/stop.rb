module Procedures::KatelloService
  class Stop < ForemanMaintain::Procedure
    metadata do
      description 'katello-service stop'
      param :only, 'A comma-separated list of services to include', :array => true
      param :exclude, 'A comma-separated list of services to skip', :array => true
      for_feature :katello_service
      tags :katello_service_stop
    end

    def run
      with_spinner('stopping katello service(s)') do |spinner|
        feature(:katello_service).make_stop(spinner, :only => @only, :exclude => @exclude)
      end
    end
  end
end
