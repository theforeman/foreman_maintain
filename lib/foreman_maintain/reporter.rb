module ForemanMaintain
  class Reporter
    class DummySpinner
      def update(_message)
        # do nothing
      end
    end
    require 'foreman_maintain/reporter/cli_reporter'

    # Each public method is a hook called by executor at the specific point
    def before_scenario_starts(_scenario); end

    def before_execution_starts(_execution); end

    def after_execution_finishes(_execution); end

    def after_scenario_finishes(_scenario); end

    def on_next_steps(_steps); end

    def with_spinner(_message, &_block)
      yield DummySpinner.new
    end

    def print(_message); end

    def puts(_message); end

    def ask(_message); end
  end
end
