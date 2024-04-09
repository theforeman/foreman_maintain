module ForemanMaintain
  module Cli
    class PackagesCommand < Base
      subcommand 'lock', 'Prevent packages from automatic update' do
        # This command is not implemented for Debian based operating systems
        interactive_option(['assumeyes'])
        def execute
          run_scenario_or_rescue do
            run_scenarios_and_exit(Scenarios::Packages::Lock.new)
          end
        end
      end

      subcommand 'unlock', 'Enable packages for automatic update' do
        # This command is not implemented for Debian based operating systems
        interactive_option(['assumeyes'])
        def execute
          run_scenario_or_rescue do
            run_scenarios_and_exit(Scenarios::Packages::Unlock.new)
          end
        end
      end

      subcommand 'status', 'Check if packages are protected against update' do
        # This command is not implemented for Debian based operating systems
        interactive_option(['assumeyes'])
        def execute
          run_scenario_or_rescue do
            run_scenarios_and_exit(Scenarios::Packages::Status.new)
          end
        end
      end

      subcommand 'check-update', 'Check for available package updates' do
        interactive_option
        def execute
          run_scenarios_and_exit(Scenarios::Packages::CheckUpdate.new)
        end
      end

      subcommand 'install', 'Install packages in an unlocked session' do
        interactive_option(['assumeyes'])
        parameter 'PACKAGES ...', 'packages to install', :attribute_name => :packages

        def execute
          run_scenarios_and_exit(
            Scenarios::Packages::Install.new(
              :packages => packages,
              :assumeyes => assumeyes?
            )
          )
        end
      end

      subcommand 'update', 'Update packages in an unlocked session' do
        interactive_option(['assumeyes'])
        parameter '[PACKAGES] ...', 'packages to update', :attribute_name => :packages
        option '--downloadonly', :flag, 'Downloads and caches package updates only',
          :default => false

        def execute
          run_scenarios_and_exit(
            Scenarios::Packages::Update.new(
              :packages => packages,
              :assumeyes => assumeyes?,
              :downloadonly => @downloadonly
            )
          )
        end
      end

      subcommand 'is-locked', 'Check if update of packages is allowed' do
        # This command is not implemented for Debian based operating systems
        interactive_option(['assumeyes'])
        def execute
          run_scenario_or_rescue do
            locked = ForemanMaintain.package_manager.versions_locked?
            puts "Packages are#{locked ? '' : ' not'} locked"
            exit_code = locked ? 0 : 1
            exit exit_code
          end
        end
      end

      def run_scenario_or_rescue
        yield
      rescue NotImplementedError
        puts 'Command is not implemented for Debian based operating systems!'
        exit 0
      end
    end
  end
end
