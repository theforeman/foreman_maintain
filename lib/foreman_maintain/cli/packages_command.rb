module ForemanMaintain
  module Cli
    class PackagesCommand < Base
      subcommand 'lock', 'Prevent packages from automatic update' do
        interactive_option
        def execute
          run_scenarios_and_exit(Scenarios::Packages::Lock.new)
        end
      end

      subcommand 'unlock', 'Enable packages for automatic update' do
        interactive_option
        def execute
          run_scenarios_and_exit(Scenarios::Packages::Unlock.new)
        end
      end

      subcommand 'status', 'Check if packages are protected against update' do
        interactive_option
        def execute
          run_scenarios_and_exit(Scenarios::Packages::Status.new)
        end
      end

      subcommand 'install', 'Install packages in an unlocked session' do
        interactive_option
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
        interactive_option
        parameter '[PACKAGES] ...', 'packages to update', :attribute_name => :packages

        def execute
          run_scenarios_and_exit(
            Scenarios::Packages::Update.new(
              :packages => packages,
              :assumeyes => assumeyes?
            )
          )
        end
      end

      subcommand 'is-locked', 'Check if update of packages is allowed' do
        interactive_option
        def execute
          locked = ForemanMaintain.package_manager.versions_locked?
          puts "Packages are#{locked ? '' : ' not'} locked"
          exit_code = locked ? 0 : 1
          exit exit_code
        end
      end
    end
  end
end
