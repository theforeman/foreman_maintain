require 'foreman_maintain/report_runner/json'
require 'foreman_maintain/report_runner/yaml'

module ForemanMaintain
  class ReportRunner
    def initialize(reporter, scenario)
      @scenario = scenario
      @reporter = reporter
      @result = []
    end

    def run
      @steps_to_run = @scenario.steps.dup

      until @steps_to_run.empty?
        step = @steps_to_run.shift
        @result << step.to_h
      end

      print_result
    end
  end
end
