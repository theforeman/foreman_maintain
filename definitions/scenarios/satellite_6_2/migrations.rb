module Scenarios::Satellite_6_2
  class Migrations < ForemanMaintain::Scenario
    metadata do
      description 'migration scripts to Satellite 6.2'
      tags :migrations, :satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
    end

    def compose
      add_steps(find_procedures(:label => :installer_upgrade))
    end
  end
end
