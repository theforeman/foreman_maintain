require 'test_helper'

require 'foreman_maintain/cli'

include CliAssertions
module ForemanMaintain
  describe Cli::HealthCommand do
    include CliAssertions
    let :command do
      %w(health)
    end

    it 'prints help' do
      assert_cmd <<OUTPUT
Usage:
    foreman-maintain health [OPTIONS] SUBCOMMAND [ARG] ...

Parameters:
    SUBCOMMAND                    subcommand
    [ARG] ...                     subcommand arguments

Subcommands:
    list                          List the checks based on criteria
    list-tags                     List the tags to use for filtering checks
    check                         Run the health checks against the system

Options:
    -h, --help                    print help
OUTPUT
    end

    describe 'list-checks' do
      let :command do
        %w(health list)
      end
      it 'lists the defined checks' do
        assert_cmd <<OUTPUT
[external-service-is-accessible] external_service_is_accessible         [pre-upgrade-check]
[present-service-is-running] present service run check                  [basic]
OUTPUT
      end
    end

    describe 'list-tags' do
      let :command do
        %w(health list-tags)
      end
      it 'lists the defined tags' do
        assert_cmd <<OUTPUT
[basic]
[pre-upgrade-check]
OUTPUT
      end
    end

    describe 'check' do
      let :command do
        %w(health check)
      end

      it 'runs the checks by label' do
        Cli::HealthCommand.any_instance.expects(:run_scenario).with do |scenario|
          scenario.filter_label.must_equal :present_service_is_running
        end
        run_cmd(['--label=present-service-is-running'])
      end

      it 'runs the default checks' do
        Cli::HealthCommand.any_instance.expects(:run_scenario).with do |scenario|
          scenario.filter_tags.must_equal [:basic]
        end
        run_cmd
      end

      it 'runs the checks by tags' do
        Cli::HealthCommand.any_instance.expects(:run_scenario).with do |scenario|
          scenario.filter_tags.must_equal [:pre_upgrade_check]
        end
        run_cmd(['--tags=pre-upgrade-check'])
      end
    end
  end
end
