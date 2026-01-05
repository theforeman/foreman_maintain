require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  describe Cli::PluginCommand do
    include CliAssertions
    let :command do
      %w[plugin]
    end

    it 'prints help' do
      assert_cmd <<~OUTPUT, :ignore_whitespace => true
        Usage:
            foreman-maintain plugin [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            purge-puppet                Remove the Puppet feature

        Options:
            -h, --help                    print help
      OUTPUT
    end

    describe 'disable-puppet' do
      let :command do
        %w[plugin purge-puppet]
      end

      it 'runs purge-puppet' do
        Cli::PluginCommand.any_instance.expects(:run_scenario).with do |scenario|
          _(scenario.context.get(:remove_data)).must_be_nil
          _(scenario.label).must_equal :puppet_disable
        end
        run_cmd
      end

      it 'passes remove_data flag' do
        Cli::PluginCommand.any_instance.expects(:run_scenario).with do |scenario|
          _(scenario.context.get(:remove_data)).must_equal true
          _(scenario.label).must_equal :puppet_disable
        end
        run_cmd(['--remove-all-data'])
      end
    end
  end
end
