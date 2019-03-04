module ForemanMaintain
  module Cli
    class PackagesCommand < Base
      subcommand 'lock', 'Prevent Foreman-related packages from automatic update' do
        interactive_option
        def execute
          run_scenarios_and_exit(Scenarios::VersionLocking::Lock.new)
        end
      end

      subcommand 'unlock', 'Enable Foreman-related packages for automatic update' do
        interactive_option
        def execute
          run_scenarios_and_exit(Scenarios::VersionLocking::Unlock.new)
        end
      end

      subcommand 'status', 'Check if Foreman-related packages are protected against update' do
        interactive_option
        def execute
          run_scenarios_and_exit(Scenarios::VersionLocking::Status.new)
        end
      end

      subcommand 'is-locked', 'Check if update of Foreman-related packages is allowed' do
        interactive_option
        def execute
          locked = feature(:package_manager).versions_locked?
          puts "Foreman related packages are#{locked ? '' : ' not'} locked"
          exit_code = locked ? 0 : 1
          exit exit_code
        end
      end
    end
  end
end
