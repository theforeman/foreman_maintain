class Checks::HammerPing < ForemanMaintain::Check
  include ForemanMaintain::Concerns::Hammer
  metadata do
    label :hammer_ping
    for_feature :hammer
    description 'Check whether all services are running using hammer ping'
    tags :default

    confine do
      feature(:katello)
    end
  end

  def run
    result = feature(:hammer).hammer_ping_cmd
    assert(result[:success],
           result[:message],
           :next_steps => Procedures::KatelloService::Restart.new(:only => result[:data]))
  end
end
