module ForemanMaintain
  module Cli
    class ReportCommand < Base
      extend Concerns::Finders

      option '--output', 'FILE', 'Output the generate report into FILE'
      subcommand 'generate', 'Generates the usage reports' do
        def execute
          scenario = run_scenario(Scenarios::Report::Generate.new({}, [:reports])).first

          # description can be used too
          report_data = scenario.steps.map(&:data).compact.reduce(&:merge).transform_keys(&:to_s)
          report_data['version'] = 1
          yaml = report_data.to_yaml
          if @output
            File.write(@output, yaml)
          else
            puts yaml
          end
          exit runner.exit_code
        end
      end
    end
  end
end
