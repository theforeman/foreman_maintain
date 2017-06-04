require 'test_helper'

module ForemanMaintain
  describe UpgradeRunner do
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
                                     'present_service pre_upgrade_checks scenario'])
    end

    it 'remembers the state of the previous run of the upgrade'

    it 'asks for confirmation before getting into pre_migrations from pre upgrade checks' do
      upgrade_runner_with_whitelist.run
      reporter.log.last.must_equal ['ask', <<-MESSAGE.strip_heredoc.strip]
        The script will now start with the modification part of the upgrade.
        Confirm to continue, [y(yes), n(no), q(quit)]
      MESSAGE
    end

    it 'does not run the pre_upgrade_checks again when already in pre_migrations phase' do
      upgrade_runner.send(:phase=, :pre_migrations)
      upgrade_runner.run
      reporter.log.first.
        must_equal ['before_scenario_starts', 'present_service pre_migrations scenario']
    end

    it 'runs migrations if pre_migrations succeed'

    it 'runs post_migrations if migrations succeed'

    it 'fails if migrations fail'

    it 'runs post_upgrade_checks if post_migrations succeed'

    it 'fails if post_migrations fail'

    it 'runs post_migrations and post_upgrade checks if pre_migrations fail'
  end
end
