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

      it 'reindexes the DB if DB is local and offline backup and OS change' do
        assume_feature_present(:instance, :postgresql_local? => true)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(false)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:different_source_os?).returns(true)
        assert_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end

      it 'doesnt reindex the DB if DB is local and offline backup and no OS change' do
        assume_feature_present(:instance, :postgresql_local? => true)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(false)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:different_source_os?).returns(false)
        refute_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end

      it 'doesnt reindex the DB if DB is local and online backup' do
        assume_feature_present(:instance, :postgresql_local? => false)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(true)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:different_source_os?).returns(true)
        refute_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end

      it 'doesnt reindex the DB if it is remote' do
        assume_feature_present(:instance, :postgresql_local? => false)
        ForemanMaintain::Utils::Backup.any_instance.stubs(:different_source_os?).returns(true)
        refute_scenario_has_step(scenario, Procedures::Restore::ReindexDatabases)
      end

      it 'drops and restores DB dumps if present' do
        assume_feature_present(:foreman_database, :configuration => {})
        assume_feature_present(:candlepin_database, :configuration => {})
        assume_feature_present(:pulpcore_database, :configuration => {})

        ForemanMaintain::Utils::Backup.any_instance.stubs(:file_map).returns(
          {
            :foreman_dump => { :present => true },
            :candlepin_dump => { :present => true },
            :pulpcore_dump => { :present => true },
            :pulp_data => { :present => true },
            :pgsql_data => { :present => true },
            :metadata => { :present => false },
          }
        )

        assert_scenario_has_step(scenario, Procedures::Restore::DropDatabases)
        assert_scenario_has_step(scenario, Procedures::Restore::ForemanDump)
        assert_scenario_has_step(scenario, Procedures::Restore::CandlepinDump)
        assert_scenario_has_step(scenario, Procedures::Restore::PulpcoreDump)
      end

      it 'does not try to drop/restore DB dumps when these are absent' do
        assume_feature_present(:foreman_database, :configuration => {})
        assume_feature_present(:candlepin_database, :configuration => {})
        assume_feature_present(:pulpcore_database, :configuration => {})

        ForemanMaintain::Utils::Backup.any_instance.stubs(:sql_dump_files_exist?).returns(false)

        refute_scenario_has_step(scenario, Procedures::Restore::DropDatabases)
        refute_scenario_has_step(scenario, Procedures::Restore::ForemanDump)
        refute_scenario_has_step(scenario, Procedures::Restore::CandlepinDump)
        refute_scenario_has_step(scenario, Procedures::Restore::PulpcoreDump)
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
