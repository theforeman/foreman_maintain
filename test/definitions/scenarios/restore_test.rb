require 'test_helper'

module Scenarios
  describe ForemanMaintain::Scenarios::Restore do
    include DefinitionsTestHelper

    let(:checks) do
      [Checks::Restore::ValidateBackup,
       Checks::Restore::ValidateHostname,
       Checks::Restore::ValidateInterfaces]
    end

    describe 'with default params' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Restore.new(:backup_dir => '.',
          :incremental_backup => false,
          :dry_run => false)
      end

      it 'composes all steps' do
        checks.each do |check|
          assert_scenario_has_step(scenario, check)
        end
        assert_scenario_has_step(scenario, Procedures::Restore::Confirmation)
        assert_scenario_has_step(scenario, Procedures::Restore::Configs)
      end

      it 'reindexes the DB if DB is local and offline backup' do
        assume_feature_present(:instance, :postgresql_local? => true)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(false)
        assert_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end

      it 'doesnt reindex the DB if DB is local and online backup' do
        assume_feature_present(:instance, :postgresql_local? => false)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(true)
        refute_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end

      it 'doesnt reindex the DB if it is remote' do
        assume_feature_present(:instance, :postgresql_local? => false)
        refute_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end
    end

    describe 'with dry_run=true' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Restore.new(:backup_dir => '.',
          :incremental_backup => false,
          :dry_run => true)
      end

      it 'composes only check steps' do
        checks.each do |check|
          assert_scenario_has_step(scenario, check)
        end
        refute_scenario_has_step(scenario, Procedures::Restore::Confirmation)
        refute_scenario_has_step(scenario, Procedures::Restore::Configs)
        refute_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end
    end
  end
end
