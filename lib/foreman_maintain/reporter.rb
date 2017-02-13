module ForemanMaintain
  class Reporter
    require 'foreman_maintain/reporter/cli_reporter'

    # Each public method is a hook called by executor at the specific point
    def before_scenario_starts(_scenario); end

    def before_execution_starts(_execution); end

    def on_execution_update(_execution, _update); end

    def after_execution_finishes(_execution); end

    def after_scenario_finishes(_scenario); end
  end
end
