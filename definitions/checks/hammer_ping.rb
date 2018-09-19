class Checks::HammerPing < ForemanMaintain::Check
  include ForemanMaintain::Concerns::Hammer
  metadata do
    label :hammer_ping
    for_feature :hammer
    description 'Check whether all services are running using hammer ping'
    tags :default
    after :services_up

    confine do
      feature(:katello)
    end
  end

  def run
    result = feature(:hammer).hammer_ping_cmd
    restart_procedure = Procedures::Service::Restart.new(:only => result[:data],
                                                         :wait_for_hammer_ping => true)
    assert(result[:success],
           result[:message],
           :next_steps => restart_procedure)
  end
end
