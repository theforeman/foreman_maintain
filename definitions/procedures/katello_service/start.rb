module Procedures::KatelloService
  class Start < ForemanMaintain::Procedure
    metadata do
      description 'katello-service start'
      param :only, 'A comma-separated list of services to include', :array => true
      param :exclude, 'A comma-separated list of services to skip', :array => true
      for_feature :katello_service
      tags :katello_service_start
    end

    def run
      with_spinner('stopping katello service(s)') do |spinner|
        feature(:katello_service).make_start(
          spinner, :only => @only, :exclude => @exclude
        )
      end
    end
  end
end
