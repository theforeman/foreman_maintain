module ForemanMaintain
  module Cli
    class PluginCommand < Base
      subcommand 'purge-puppet', 'Remove the Puppet feature' do
        option ['-f', '--remove-all-data'], :flag, 'Purge all the Puppet data',
               :attribute_name => :remove_data

        def execute
          run_scenarios_and_exit(Scenarios::Puppet::RemovePuppet.new(:remove_data => remove_data?))
        end
      end
    end
  end
end
