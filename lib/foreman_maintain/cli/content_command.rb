module ForemanMaintain
  module Cli
    class ContentCommand < Base
      subcommand 'prepare', 'Prepare content for Pulp 3' do
        def execute
          run_scenarios_and_exit(Scenarios::Content::Prepare.new)
        end
      end

      unless ForemanMaintain.detector.feature(:satellite) ||
             ForemanMaintain.detector.feature(:capsule)
        subcommand 'switchover', 'Switch support for certain content from Pulp 2 to Pulp 3' do
          def execute
            run_scenarios_and_exit(Scenarios::Content::Switchover.new)
          end
        end
      end

      subcommand 'prepare-abort', 'Abort all running Pulp 2 to Pulp 3 migration tasks' do
        def execute
          run_scenarios_and_exit(Scenarios::Content::PrepareAbort.new)
        end
      end

      subcommand 'migration-stats', 'Retrieve Pulp 2 to Pulp 3 migration statistics' do
        def execute
          run_scenarios_and_exit(Scenarios::Content::MigrationStats.new)
        end
      end
    end
  end
end
