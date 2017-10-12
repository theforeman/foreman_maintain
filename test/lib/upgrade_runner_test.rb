require 'test_helper'

module ForemanMaintain
  describe UpgradeRunner do
    after do
      ForemanMaintain.detector.refresh
      TestHelper.reset
    end

    let :reporter do
      Support::LogReporter.new
    end

    let(:upgrade_runner) do
      UpgradeRunner.new('1.15', reporter)
    end

    let(:upgrade_runner_with_whitelist) do
      UpgradeRunner.new('1.15', reporter,
                        :whitelist => %w[present-service-is-running service-is-stopped])
    end

    it 'sets assumeyes from options' do
      upgrade_runner = UpgradeRunner.new('1.15', reporter, :assumeyes => true)
      assert(upgrade_runner.assumeyes?)
    end

    it 'lists versions available for upgrading, based on available scenarios' do
      UpgradeRunner.available_targets.must_equal ['1.15']
    end

    it 'constructs set of scenarios for upgrade' do
      upgrade_runner.scenario(:pre_upgrade_checks).
        must_be_kind_of Scenarios::PresentUpgrade::PreUpgradeChecks
    end

    it 'runs pre_upgrade_checks first' do
      upgrade_runner.run
      reporter.log.first.must_equal(['before_scenario_starts',
                                     :present_upgrade_pre_upgrade_checks])
    end

    it 'asks for confirmation before getting into pre_migrations from pre upgrade checks' do
      upgrade_runner_with_whitelist.run
      reporter.log.last.must_equal ['ask', <<-MESSAGE.strip_heredoc.strip]
        The pre-upgrade checks indicate that the system is ready for upgrade.
        It's recommended to perform a backup at this stage.
        Confirm to continue with the the modification part of the upgrade, [y(yes), n(no), q(quit)]
      MESSAGE
      assert_equal(:pre_upgrade_checks, upgrade_runner_with_whitelist.phase,
                   'The phase should not be switched until confirmed')
    end

    it 'remembers the state of the previous run of the upgrade' do
      TestHelper.migrations_fail_at = :migrations
      reporter.input << 'y'
      upgrade_runner_with_whitelist.storage.data.clear
      upgrade_runner_with_whitelist.run
      upgrade_runner_with_whitelist.save
      original_scenario = upgrade_runner_with_whitelist.scenario(:pre_upgrade_checks)

      ForemanMaintain.detector.refresh
      new_upgrade_runner = UpgradeRunner.new('1.15', reporter)
      new_upgrade_runner.load
      new_upgrade_runner.phase.must_equal :migrations
      restored_scenario = new_upgrade_runner.scenario(:pre_upgrade_checks)
      restored_scenario.steps.map { |s| s.execution.status }.
        must_equal(original_scenario.steps.map { |step| step.execution.status })
    end

    it 'remembers the current target version' do
      TestHelper.migrations_fail_at = :migrations
      reporter.input << 'y'
      upgrade_runner_with_whitelist.storage.data.clear
      upgrade_runner_with_whitelist.run
      upgrade_runner_with_whitelist.save
      UpgradeRunner.current_target_version.must_equal '1.15'
      UpgradeRunner.available_targets.must_equal(['1.15'])
    end

    it 'does not remember the current target version when failed on pre_upgrade_checks ===' do
      TestHelper.migrations_fail_at = :pre_upgrade_checks
      upgrade_runner_with_whitelist.run
      upgrade_runner_with_whitelist.save
      UpgradeRunner.current_target_version.must_be_nil
    end

    it 'cleans the state when the upgrade finished successfully' do
      reporter.input << 'y'
      upgrade_runner_with_whitelist.storage.data.clear
      upgrade_runner_with_whitelist.run
      upgrade_runner_with_whitelist.save

      new_upgrade_runner = UpgradeRunner.new('1.15', reporter)
      new_upgrade_runner.load
      new_upgrade_runner.phase.must_equal :pre_upgrade_checks
      UpgradeRunner.current_target_version.must_be_nil
    end

    it 'does not run the pre_upgrade_checks again when already in pre_migrations phase' do
      upgrade_runner.send(:phase=, :pre_migrations)
      upgrade_runner.run
      reporter.log.wont_include ['before_execution_starts', :present_service_is_running]
      reporter.log.must_include ['before_execution_starts', :upgrade_pre_migration]
    end

    it 'runs migrations if pre_migrations succeed' do
      reporter.input << 'y'
      upgrade_runner_with_whitelist.run
      reporter.log.must_include ['before_execution_starts', :upgrade_migration]
    end

    it 'runs post_migrations and post_upgrade checks if pre_migrations fail' do
      reporter.input << 'y'
      TestHelper.migrations_fail_at = :pre_migrations
      upgrade_runner_with_whitelist.run
      upgrade_runner_with_whitelist.phase.must_equal :pre_upgrade_checks
      reporter.log.wont_include ['before_execution_starts', :upgrade_migration]
      reporter.log.must_include ['before_execution_starts', :upgrade_post_migration]
      reporter.log.must_include ['before_execution_starts', :upgrade_post_upgrade_check]
      upgrade_runner_with_whitelist.exit_code.must_equal 1
    end

    it 'runs post_migrations if migrations succeed' do
      reporter.input << 'y'
      upgrade_runner_with_whitelist.run
      reporter.log.must_include ['before_execution_starts', :upgrade_post_migration]
    end

    it 'fails if migrations fail' do
      reporter.input << 'y'
      TestHelper.migrations_fail_at = :migrations
      upgrade_runner_with_whitelist.run
      upgrade_runner_with_whitelist.phase.must_equal :migrations
      upgrade_runner_with_whitelist.exit_code.must_equal 1
    end

    it 'runs post_upgrade_checks if post_migrations succeed' do
      reporter.input << 'y'
      upgrade_runner_with_whitelist.run
      reporter.log.must_include ['before_execution_starts', :upgrade_post_upgrade_check]
    end

    it 'fails if post_migrations fail' do
      reporter.input << 'y'
      TestHelper.migrations_fail_at = :post_migrations
      upgrade_runner_with_whitelist.run
      upgrade_runner_with_whitelist.phase.must_equal :post_migrations
      upgrade_runner_with_whitelist.exit_code.must_equal 1
    end
  end
end
