module ForemanMaintain
  module Cli
    class ContentCommand < Base
      subcommand 'prepare', 'Prepare content for Pulp 3' do
        def execute
          run_scenarios_and_exit(Scenarios::Content::Prepare.new)
        end
      end

      subcommand 'switchover', 'Switch support for certain content from Pulp 2 to Pulp 3' do
        def execute
          run_scenarios_and_exit(Scenarios::Content::Switchover.new)
        end
      end
    end
  end
end
