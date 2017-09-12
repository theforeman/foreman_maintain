module Scenarios::Dummy
  class Success < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Success])
    end
  end

  class RunOnce < ForemanMaintain::Scenario
    def compose
      add_steps([Procedures::RunOnce, Checks::Dummy::Fail])
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

  class FailMultiple < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Fail, Checks::Dummy::Fail2, Checks::Dummy::Success])
    end
  end

  class WarnAndFail < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Warn, Checks::Dummy::Fail, Checks::Dummy::Success])
    end
  end

  class FailFast < Fail
    metadata do
      run_strategy :fail_fast
    end
  end

  class FailSlow < Fail
    metadata do
      run_strategy :fail_slow
    end
  end
end
