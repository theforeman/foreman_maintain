class Checks::ServicesUp < ForemanMaintain::Check
  metadata do
    label :services_up
    description 'Check whether all services are running'
    tags :default
  end

  def run
    failed_services = feature(:service).existing_services.reject(&:running?)
    restart_procedure = Procedures::Service::Restart.new(
      :only => failed_services,
      :wait_for_hammer_ping => !!feature(:katello)
    )
    assert(failed_services.empty?,
           'Following services are not running: ' + failed_services.map(&:to_s).join(', '),
           :next_steps => restart_procedure)
  end
end
