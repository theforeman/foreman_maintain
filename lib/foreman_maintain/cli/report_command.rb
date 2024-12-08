module ForemanMaintain
  module Cli
    class ReportCommand < Base
      extend Concerns::Finders

      subcommand 'generate', 'Generates the usage reports' do
        def execute
          scenario = run_scenario(Scenarios::Report::Generate.new({}, [:reports])).first

          # description can be used too
          report_data = scenario.steps.map(&:data).reduce(&:merge).transform_keys(&:to_s)
          # require 'pry'
          # binding.pry
          puts report_data.to_yaml
          exit runner.exit_code
        end
      end
    end
  end
end
