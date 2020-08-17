require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  include CliAssertions
  describe Cli::UpgradeCommand do
    include CliAssertions
    before do
      ForemanMaintain.detector.refresh
      UpgradeRunner.clear_current_target_version
    end
    let :command do
      %w[upgrade]
    end

    it 'prints help' do
      assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
        Usage:
            foreman-maintain upgrade [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            list-versions                 List versions this system is upgradable to
            check                         Run pre-upgrade checks before upgrading to specified version
            run                           Run full upgrade to a specified version

        Options:
            -h, --help                    print help
      OUTPUT
    end

    describe 'list-versions' do
      let :command do
        %w[upgrade list-versions --disable-self-upgrade]
      end
      it 'lists the available versions' do
        assert_cmd <<-OUTPUT.strip_heredoc
          1.15
        OUTPUT
      end
    end

    describe 'check' do
      let :command do
        %w[upgrade check --disable-self-upgrade]
      end

      it 'runs the upgrade checks for version' do
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_upgrade_checks)
        run_cmd(['--target-version=1.15'])
      end

      it 'should raise UsageError and exit with code 1' do
        Cli::MainCommand.any_instance.expects(:exit!)

        run_cmd([])
      end
    end

    describe 'run' do
      let :command do
        %w[upgrade run --disable-self-upgrade]
      end

      it 'runs the full upgrade for version' do
        UpgradeRunner.any_instance.expects(:run)
        run_cmd(['--target-version=1.15'])
      end

      it 'remembers the current target version' do
        Cli::MainCommand.any_instance.expects(:exit!)
        assert_cmd <<-OUTPUT.strip_heredoc
          --target-version not specified
          Possible target versions are:
          1.15
        OUTPUT

        UpgradeRunner.current_target_version = '1.15'
        UpgradeRunner.any_instance.expects(:run)
        Cli::MainCommand.any_instance.expects(:exit!)

        run_cmd

        assert_cmd(<<-OUTPUT.strip_heredoc, ['--target-version', '1.16'])
          Can't set target version 1.16, 1.15 already in progress
        OUTPUT
      end

      it 'with --phase it runs only a specific phase of the upgrade' do
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_migrations)
        run_cmd(['--phase=pre_migrations', '--target-version=1.15'])
      end

      it 'raises an exception for invalid phase' do
        Cli::MainCommand.any_instance.expects(:exit!)
        assert_cmd(<<-OUTPUT.strip_heredoc, ['--phase=foo_bar', '--target-version', '1.16'])
          Unknown phase foo_bar
        OUTPUT
      end
    end
  end
end
