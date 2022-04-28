module Scenarios::DummySkipWhitelist
  class Fail < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Fail, Checks::Dummy::Success])
    end
  end

  class FailMultiple < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Fail, Checks::Dummy::FailSkipWhitelist,
                 Checks::Dummy::Success])
    end
  end

  class WarnAndFail < ForemanMaintain::Scenario
    def compose
      add_steps([Checks::Dummy::Warn, Checks::Dummy::Fail, Checks::Dummy::FailSkipWhitelist,
                 Checks::Dummy::Success])
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
