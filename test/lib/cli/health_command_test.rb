require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  include CliAssertions
  describe Cli::HealthCommand do
    include CliAssertions
    let :command do
      %w[health]
    end

    it 'prints help' do
      assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
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
        %w[health list]
      end
      it 'lists the defined checks' do
        assert_cmd <<-OUTPUT.strip_heredoc
          [dummy-check-fail] Check that ends up with fail
          [dummy-check-fail2] Check that ends up with fail
          [dummy-check-fail-skipwhitelist] Check that ends up with fail
          [dummy-check-success] Check that ends up with success
          [dummy-check-warn] Check that ends up with warning
          [external-service-is-accessible] External_service_is_accessible         [pre-upgrade-check]
          [present-service-is-running] Present service run check                  [default]
          [service-is-stopped] Service not running check                          [default]
          [upgrade-post-upgrade-check] Procedures::Upgrade::PostUpgradeCheck      [post-upgrade-checks]
        OUTPUT
      end
    end

    describe 'list-tags' do
      let :command do
        %w[health list-tags]
      end
      it 'lists the defined tags' do
        assert_cmd <<-OUTPUT.strip_heredoc
          [default]
          [post-upgrade-checks]
          [pre-upgrade-check]
        OUTPUT
      end
    end

    describe 'check' do
      let :command do
        %w[health check]
      end

      it 'runs the checks by label' do
        Cli::HealthCommand.any_instance.expects(:run_scenario).with do |scenario|
          scenario.filter_label.must_equal :present_service_is_running
        end
        run_cmd(['--label=present-service-is-running'])
      end

      it 'runs the default checks' do
        Cli::HealthCommand.any_instance.expects(:run_scenario).with do |scenario|
          scenario.filter_tags.must_equal [:default]
        end
        run_cmd
      end

      it 'runs the checks by tags' do
        Cli::HealthCommand.any_instance.expects(:run_scenario).with do |scenario|
          scenario.filter_tags.must_equal [:pre_upgrade_check]
        end
        run_cmd(['--tags=pre-upgrade-check'])
      end

      it 'raises errors on empty arguments' do
        assert_cmd <<-OUTPUT.strip_heredoc, %w[--label]
          ERROR: option '--label': value not specified

          See: 'foreman-maintain health check --help'
        OUTPUT

        assert_cmd <<-OUTPUT.strip_heredoc, %w[--tags]
          ERROR: option '--tags': value not specified

          See: 'foreman-maintain health check --help'
        OUTPUT
      end
    end
  end
end
