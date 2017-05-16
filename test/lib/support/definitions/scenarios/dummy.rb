require 'checks/dummy'
module Scenarios::Dummy
  class Success < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Success])
    end
  end

  class Warn < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Warn, Checks::Dummy::Success])
    end
  end

  class Fail < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Fail, Checks::Dummy::Success])
    end
  end

  class WarnAndFail < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Warn, Checks::Dummy::Fail, Checks::Dummy::Success])
    end
  end
end
