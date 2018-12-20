require 'foreman_maintain/cli/report/params/size'
require 'foreman_maintain/cli/report/params/output'

module ForemanMaintain
  module Cli
    class ReportCommand < SystemReport
      ForemanMaintain.available_reports(nil).each do |report|
        subcommand(report.label.dashize, report.description) do
          output_format_option
          limit_table_size_option if report.label == :table_sizes

          def execute
            label = invocation_path.split.last.underscorize
            report = report(label.to_sym)
            scenario = ForemanMaintain::Scenario.new
            scenario.add_step(report.new(build_params_hash(report)))
            run_scenario(scenario)
          end

          def build_params_hash(report)
            Hash[report.params.map { |param, _obj| [param, send(param)] }]
          end
        end
      end

      subcommand('all', 'Generate all reports') do
        output_format_option

        def execute
          scenario = ForemanMaintain::Scenario.new
          scenario.add_steps(find_reports)
          run_scenario(scenario)
        end
      end
    end
  end
end
