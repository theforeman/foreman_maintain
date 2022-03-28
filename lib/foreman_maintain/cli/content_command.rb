module ForemanMaintain
  module Cli
    class ContentCommand < Base
      subcommand 'prepare', 'Prepare content for Pulp 3' do
        option ['-q', '--quiet'], :flag, 'Keep the output on a single line'
        def execute
          run_scenarios_and_exit(Scenarios::Content::Prepare.new(:quiet => quiet?))
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

      subcommand 'migration-reset', 'Reset the Pulp 2 to Pulp 3 migration data (pre-switchover)' do
        def execute
          run_scenarios_and_exit(Scenarios::Content::MigrationReset.new)
        end
      end

      subcommand 'cleanup-repository-metadata', 'Cleanup old repository metadata under Pulp 2' do
        option ['-r', '--remove-files'], :flag, 'Remove the files instead of just listing them.',
               :attribute_name => :remove_files

        def execute
          run_scenarios_and_exit(
            Scenarios::Content::CleanupRepositoryMetadata.new(:remove_files => @remove_files)
          )
        end
      end

      subcommand 'remove-pulp2', 'Remove pulp2 and mongodb packages and data' do
        interactive_option(%w[assumeyes plaintext])
        def execute
          run_scenarios_and_exit(
            Scenarios::Content::RemovePulp2.new(:assumeyes => assumeyes?)
          )
        end
      end

      subcommand 'fix-pulpcore-artifact-ownership',
                 'Update filesystem ownership for Pulpcore artifacts' do
        interactive_option(%w[assumeyes plaintext])
        def execute
          run_scenarios_and_exit(
            Scenarios::Content::FixPulpcoreArtifactOwnership.new(:assumeyes => assumeyes?)
          )
        end
      end
    end
  end
end
