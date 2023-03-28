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

    def foreman_maintain_update_available
      ForemanMaintain.stubs(:el?).returns(true)
      PackageManagerTestHelper.mock_package_manager
      FakePackageManager.any_instance.stubs(:update).with('rubygem-foreman_maintain',
        :assumeyes => true).returns(true)
      # rubocop:disable Layout/LineLength
      FakePackageManager.any_instance.stubs(:update_available?).with('rubygem-foreman_maintain').returns(true)
      # rubocop:enable Layout/LineLength
    end

    def foreman_maintain_update_unavailable
      ForemanMaintain.stubs(:el?).returns(true)
      PackageManagerTestHelper.mock_package_manager
      # rubocop:disable Layout/LineLength
      FakePackageManager.any_instance.stubs(:update_available?).with('rubygem-foreman_maintain').returns(false)
      # rubocop:enable Layout/LineLength
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
        %w[upgrade list-versions]
      end
      it 'run self upgrade if upgrade available for foreman-maintain' do
        foreman_maintain_update_available
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...

        Updating rubygem-foreman_maintain package.

        The rubygem-foreman_maintain package successfully updated.
        Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'inform if no updates available for foreman-maintain' do
        foreman_maintain_update_unavailable
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...
        Nothing to update, can't find new version of rubygem-foreman_maintain.
        1.15
        OUTPUT
      end

      it 'skip self upgrade and lists the available versions' do
        command << '--disable-self-upgrade'
        assert_cmd <<-OUTPUT.strip_heredoc
          1.15
        OUTPUT
      end
    end

    describe 'check' do
      let :command do
        %w[upgrade check]
      end

      it 'run self upgrade if upgrade available for foreman-maintain' do
        foreman_maintain_update_available
        command << '--target-version=1.15'
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...

        Updating rubygem-foreman_maintain package.

        The rubygem-foreman_maintain package successfully updated.
        Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'runs the upgrade checks when update is not available for foreman-maintain' do
        foreman_maintain_update_unavailable
        command << '--target-version=1.15'
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_upgrade_checks)
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...
        Nothing to update, can't find new version of rubygem-foreman_maintain.
        OUTPUT
      end

      it 'runs the upgrade checks for version with disable-self-upgrade' do
        foreman_maintain_update_available
        command << '--disable-self-upgrade'
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_upgrade_checks)
        run_cmd(['--target-version=1.15'])
      end

      it 'should raise UsageError and exit with code 1' do
        Cli::MainCommand.any_instance.stubs(:exit!)

        run_cmd([])
      end
    end

    describe 'run' do
      let :command do
        %w[upgrade run]
      end

      it 'run self upgrade if upgrade available for foreman-maintain' do
        foreman_maintain_update_available
        command << '--target-version=1.15'
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...

        Updating rubygem-foreman_maintain package.

        The rubygem-foreman_maintain package successfully updated.
        Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'runs the full upgrade when update is not available for foreman-maintain' do
        foreman_maintain_update_unavailable
        command << '--target-version=1.15'
        UpgradeRunner.any_instance.expects(:run)
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...
        Nothing to update, can't find new version of rubygem-foreman_maintain.
        OUTPUT
      end

      it 'skip self upgrade and runs the full upgrade for version' do
        command << '--disable-self-upgrade'
        UpgradeRunner.any_instance.expects(:run)
        run_cmd(['--target-version=1.15'])
      end

      it 'runs the self upgrade when update available for rubygem-foreman_maintain' do
        foreman_maintain_update_available
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...

        Updating rubygem-foreman_maintain package.

        The rubygem-foreman_maintain package successfully updated.
        Re-run foreman-maintain with required options!
        OUTPUT

        UpgradeRunner.current_target_version = '1.15'

        run_cmd

        assert_cmd(<<-OUTPUT.strip_heredoc, ['--target-version', '1.16'])
        Checking for new version of rubygem-foreman_maintain...

        Updating rubygem-foreman_maintain package.

        The rubygem-foreman_maintain package successfully updated.
        Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'remembers the current target version and informs no update available' do
        foreman_maintain_update_unavailable
        Cli::MainCommand.any_instance.expects(:exit!).twice
        assert_cmd <<-OUTPUT.strip_heredoc
        Checking for new version of rubygem-foreman_maintain...
        Nothing to update, can't find new version of rubygem-foreman_maintain.
        --target-version not specified
        Possible target versions are:
        1.15
        OUTPUT

        UpgradeRunner.current_target_version = '1.15'
        UpgradeRunner.any_instance.expects(:run)

        run_cmd

        assert_cmd(<<-OUTPUT.strip_heredoc, ['--target-version', '1.16'])
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.
          Can't set target version 1.16, 1.15 already in progress
        OUTPUT
      end

      it 'remembers the current target version when self upgrade disabled' do
        command << '--disable-self-upgrade'
        Cli::MainCommand.any_instance.expects(:exit!)
        assert_cmd <<-OUTPUT.strip_heredoc
          --target-version not specified
          Possible target versions are:
          1.15
        OUTPUT
      end

      it 'does not allow the another upgrade when one is going on' do
        foreman_maintain_update_unavailable
        UpgradeRunner.current_target_version = '1.15'
        Cli::MainCommand.any_instance.expects(:exit!)

        assert_cmd(<<-OUTPUT.strip_heredoc, ['--target-version', '1.16'])
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.
          Can't set target version 1.16, 1.15 already in progress
        OUTPUT
      end

      it 'with --phase it runs only a specific phase of the upgrade' do
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_migrations)
        assert_cmd(<<-OUTPUT.strip_heredoc, ['--phase=pre_migrations', '--target-version=1.15'])
          Checking for new version of #{ForemanMaintain.main_package_name}...
          Nothing to update, can't find new version of #{ForemanMaintain.main_package_name}.
        OUTPUT
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
