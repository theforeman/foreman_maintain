module ForemanMaintain::Scenarios
  class DropForemanDocker < ForemanMaintain::Scenario
     metadata do
      description 'Procedures to drop foreman_docker'
      tags :foreman_docker
    end

    def compose
      add_step(Procedures::ForemanDocker::RemoveForemanDocker.new)
      add_step(Procedures::Service::Stop.new(:only => ['httpd']))
      add_step(Procedures::Foreman::ApipieCache.new)
      add_step(Procedures::Service::Start.new(:only => ['httpd']))
    end
  end
end
