module Procedures::KatelloService
  class Restart < ForemanMaintain::Procedure
    metadata do
      description 'katello-service restart'
      param :only, 'A comma-separated list of services to include', :array => true
      param :exclude, 'A comma-separated list of services to skip', :array => true
    end

    def run
      with_spinner('restarting katello service(s)') do |spinner|
        spinner.update('Restarting services')
        feature(:katello_service).restart(:only => @only, :exclude => @exclude)
        feature(:katello_service).hammer_ping_retry(spinner)
      end
    end

    def runtime_message
      msg = 'katello-service restart'
      msg += "--only #{@only.join(',')}" unless @only.empty?
      msg += "--exclude #{@exclude.join(',')}" unless @exclude.empty?
      msg
    end
  end
end
