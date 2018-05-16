module ForemanMaintain
  module Cli
    class MaintenanceModeCommand < Base
      extend Concerns::Finders

      subcommand 'start', 'Start maintenance-mode' do
        def execute
          scenario = Scenarios::MaintenanceModeStart.new
          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'stop', 'Stop maintenance-mode' do
        def execute
          scenario = Scenarios::MaintenanceModeStop.new
          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'status', 'Get maintenance-mode status' do
        def execute
          scenario = Scenarios::MaintenanceModeStatus.new
          run_scenario(scenario)
          file_check_procedure = fetch_procedure(
            scenario, Procedures::MaintenanceFile::Check
          )
          if file_check_procedure.exit_code_to_override
            exit file_check_procedure.exit_code_to_override
          else
            exit runner.exit_code
          end
        end

        def fetch_procedure(scenario, procedure_class_name)
          scenario.steps.find { |procedure| procedure.class.eql?(procedure_class_name) }
        end
      end
    end
  end
end
