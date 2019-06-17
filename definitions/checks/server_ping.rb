class Checks::ServerPing < ForemanMaintain::Check
  metadata do
    description 'Check whether all services are running using the ping call'
    tags :default
    after :services_up
  end

  def run
    response = feature(:instance).ping
    restart_procedure = Procedures::Service::Restart.new(
      :only => response.data[:failing_services],
      :wait_for_server_response => true
    )
    assert(response.success?, response.message, :next_steps => restart_procedure)
  end
end
