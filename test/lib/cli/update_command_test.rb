require 'test_helper'
require 'foreman_maintain'

module ForemanMaintain
  include CliAssertions
  describe Cli::UpdateCommand do
    include CliAssertions
    before do
      ForemanMaintain.stubs(:el?).returns(true)
      ForemanMaintain.detector.refresh
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
        %w[update]
      end

      it 'prints help' do
        assert_cmd <<~OUTPUT, :ignore_whitespace => true
          Usage:
              foreman-maintain update [OPTIONS] SUBCOMMAND [ARG] ...

          Parameters:
              SUBCOMMAND                    subcommand
              [ARG] ...                     subcommand arguments

          Subcommands:
              check                         Run pre-update checks before updating
              run                           Run an update

          Options:
              -h, --help                    print help
        OUTPUT
      end
    end

    describe 'check' do
      let :command do
        %w[update check]
      end

      it 'should raise UsageError and exit with code 1' do
        Cli::MainCommand.any_instance.stubs(:exit!)

        run_cmd([])
      end

      it 'run self update if update available for foreman-maintain' do
        foreman_maintain_update_available
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'runs the update checks when update is not available for foreman-maintain' do
        foreman_maintain_update_unavailable
        UpdateRunner.any_instance.expects(:run_phase).with(:pre_update_checks)
        UpdateRunner.any_instance.expects(:available?).returns(true)
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.
        OUTPUT
      end

      it 'runs the update checks for version with disable-self-update' do
        foreman_maintain_update_available
        command << '--disable-self-update'
        UpdateRunner.any_instance.expects(:run_phase).with(:pre_update_checks)
        UpdateRunner.any_instance.expects(:available?).returns(true)
        run_cmd
      end

      it 'throws an error message if no update is available' do
        foreman_maintain_update_unavailable
        UpdateRunner.any_instance.expects(:available?).twice.returns(false)

        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.

          This version of foreman-maintain only supports 3.15.0,
          but the installed version of FakeyFakeFake is 3.14.

          Therefore the update command is not available right now.

          Please install a version of foreman-maintain that supports 3.14
          or perform an upgrade to 3.15.0 using the upgrade command.
        OUTPUT

        run_cmd([])
      end
    end

    describe 'run' do
      let :command do
        %w[update run]
      end

      it 'run self update if update available for foreman-maintain' do
        foreman_maintain_update_available
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT
      end

      it 'runs the update when update is not available for foreman-maintain' do
        foreman_maintain_update_unavailable
        UpdateRunner.any_instance.expects(:available?).returns(true)
        UpdateRunner.any_instance.expects(:run)
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.
        OUTPUT
      end

      it 'skip self update and runs the full update for version' do
        command << '--disable-self-update'
        UpdateRunner.any_instance.expects(:run)
        UpdateRunner.any_instance.expects(:available?).returns(true)
        run_cmd
      end

      it 'throws an error message if no update is available' do
        foreman_maintain_update_unavailable
        UpdateRunner.any_instance.expects(:available?).twice.returns(false)

        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...
          Nothing to update, can't find new version of rubygem-foreman_maintain.

          This version of foreman-maintain only supports 3.15.0,
          but the installed version of FakeyFakeFake is 3.14.

          Therefore the update command is not available right now.

          Please install a version of foreman-maintain that supports 3.14
          or perform an upgrade to 3.15.0 using the upgrade command.
        OUTPUT

        run_cmd([])
      end

      it 'runs the self update when update available for rubygem-foreman_maintain' do
        foreman_maintain_update_available
        assert_cmd <<~OUTPUT
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT

        run_cmd

        assert_cmd(<<~OUTPUT)
          Checking for new version of rubygem-foreman_maintain...

          Updating rubygem-foreman_maintain package.

          The rubygem-foreman_maintain package successfully updated.
          Re-run foreman-maintain with required options!
        OUTPUT
      end
    end
  end
end
