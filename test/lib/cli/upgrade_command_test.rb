require 'test_helper'
require 'foreman_maintain/cli'

module ForemanMaintain
  include CliAssertions
  describe Cli::UpgradeCommand do
    include CliAssertions
    before do
      ForemanMaintain.stubs(:el?).returns(true)
      ForemanMaintain.detector.refresh
      UpgradeRunner.clear_current_target_version
    end

    def foreman_maintain_update_available
      PackageManagerTestHelper.mock_package_manager
      FakePackageManager.any_instance.stubs(:update).with('rubygem-foreman_maintain',
        :assumeyes => true).returns(true)
      # rubocop:disable Layout/LineLength
      FakePackageManager.any_instance.stubs(:update_available?).with('rubygem-foreman_maintain').returns(true)
      # rubocop:enable Layout/LineLength
    end

    def foreman_maintain_update_unavailable
      PackageManagerTestHelper.mock_package_manager
      # rubocop:disable Layout/LineLength
      FakePackageManager.any_instance.stubs(:update_available?).with('rubygem-foreman_maintain').returns(false)
      # rubocop:enable Layout/LineLength
    end

    describe 'help' do
      let :command do
        %w[upgrade]
      end

      it 'prints help' do
        assert_cmd <<~OUTPUT, :ignore_whitespace => true
          Usage:
              foreman-maintain upgrade [OPTIONS] SUBCOMMAND [ARG] ...

          Parameters:
              SUBCOMMAND                    subcommand
              [ARG] ...                     subcommand arguments

          Subcommands:
              check                         Run pre-upgrade checks before upgrading to specified version
              run                           Run full upgrade to a specified version

          Options:
              -h, --help                    print help
        OUTPUT
      end
    end

    describe 'check' do
      let :command do
        %w[upgrade check]
      end

      it 'run self upgrade if upgrade available for foreman-maintain' do
        foreman_maintain_update_available
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'runs the upgrade checks when update is not available for foreman-maintain' do
        foreman_maintain_update_unavailable
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_upgrade_checks)
        UpgradeRunner.any_instance.expects(:available?).returns(true)
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.
        OUTPUT
      end

      it 'runs the upgrade checks for version with disable-self-upgrade' do
        foreman_maintain_update_available
        command << '--disable-self-upgrade'
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_upgrade_checks)
        UpgradeRunner.any_instance.expects(:available?).returns(true)
        run_cmd([])
      end

      it 'throws an error message if no upgrade is available' do
        foreman_maintain_update_unavailable
        UpgradeRunner.any_instance.expects(:available?).twice.returns(false)

        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.

          There are no upgrades available.
          The current version of FakeyFakeFake is 3.14.
          Consider using the update command.
        OUTPUT

        run_cmd([])
      end
    end

    describe 'run' do
      let :command do
        %w[upgrade run]
      end

      it 'run self upgrade if upgrade available for foreman-maintain' do
        foreman_maintain_update_available
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'runs the full upgrade when update is not available for foreman-maintain' do
        foreman_maintain_update_unavailable
        UpgradeRunner.any_instance.expects(:run)
        UpgradeRunner.any_instance.expects(:available?).returns(true)
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.
        OUTPUT
      end

      it 'skip self upgrade and runs the full upgrade for version' do
        command << '--disable-self-upgrade'
        UpgradeRunner.any_instance.expects(:run)
        UpgradeRunner.any_instance.expects(:available?).returns(true)
        run_cmd([])
      end

      it 'throws an error message if no upgrade is available' do
        foreman_maintain_update_unavailable
        UpgradeRunner.any_instance.expects(:available?).twice.returns(false)

        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.

          There are no upgrades available.
          The current version of FakeyFakeFake is 3.14.
          Consider using the update command.
        OUTPUT

        run_cmd([])
      end

      it 'runs the self upgrade when update available for rubygem-foreman_maintain' do
        foreman_maintain_update_available
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT

        UpgradeRunner.current_target_version = '1.15'

        run_cmd

        assert_cmd(<<~OUTPUT, [])
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT
      end
    end
  end
end
