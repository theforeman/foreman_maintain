class Checks::ServerPing < ForemanMaintain::Check
  metadata do
    description 'Check whether all services are running using the ping call'
    tags :default
    after :services_up
  end

  def run
    result = feature(:instance).ping?
    restart_procedure = Procedures::Service::Restart.new(
      :only => feature(:instance).last_ping_failing_services,
      :wait_for_server_response => true
    )
    assert(result, feature(:instance).last_ping_status, :next_steps => restart_procedure)
  end
end
