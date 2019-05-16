module ForemanMaintain
  module Cli
    class ServiceCommand < Base
      extend Concerns::Finders

      subcommand 'start', 'Start applicable services' do
        service_options

        def execute
          scenario = Scenarios::ServiceStart.new(
            :only => only,
            :exclude => exclude
          )

          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'stop', 'Stop applicable services' do
        service_options

        def execute
          scenario = Scenarios::ServiceStop.new(
            :only => only,
            :exclude => exclude
          )

          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'restart', 'Restart applicable services' do
        service_options
        if feature(:katello)
          option ['-p', '--wait-for-server-response', '--wait-for-hammer-ping'], :flag,
                 'Wait for hammer ping to return successfully before terminating',
                 :attribute_name => :wait_for_server_response
        end

        def execute
          scenario = Scenarios::ServiceRestart.new(
            :only => only,
            :exclude => exclude,
            :wait_for_server_response => option_wrapper(:wait_for_server_response?)
          )

          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'status', 'Get statuses of applicable services' do
        service_options
        option ['-b', '--brief'], :flag, 'Print only service name and status'
        option ['-f', '--failing'], :flag, 'List only services which are not running'

        def execute
          scenario = Scenarios::ServiceStatus.new(
            :only => only,
            :exclude => exclude,
            :brief => brief?,
            :failing => failing?
          )

          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'list', 'List applicable services' do
        service_options

        def execute
          scenario = Scenarios::ServiceList.new(
            :only => only,
            :exclude => exclude,
            :action => 'status'
          )

          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'enable', 'Enable applicable services' do
        service_options

        def execute
          scenario = Scenarios::ServiceEnable.new(
            :only => only,
            :exclude => exclude, :action => 'status'
          )

          run_scenario(scenario)
          exit runner.exit_code
        end
      end

      subcommand 'disable', 'Disable applicable services' do
        service_options

        def execute
          scenario = Scenarios::ServiceDisable.new(
            :only => only,
            :exclude => exclude,
            :action => 'status'
          )

          run_scenario(scenario)
          exit runner.exit_code
        end
      end
    end
  end
end
