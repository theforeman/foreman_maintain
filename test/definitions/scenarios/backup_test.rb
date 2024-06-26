require 'test_helper'

module Scenarios
  describe ForemanMaintain::Scenarios::Backup do
    include DefinitionsTestHelper

    before do
      %w[candlepin_database foreman_database pulpcore_database].each do |feature|
        assume_feature_present(feature.to_sym) do |db|
          db.any_instance.stubs(:local?).returns(true)
        end
      end
    end

    describe 'offline' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Backup.new(:backup_dir => '.', :strategy => :offline)
      end

      it 'composes all steps' do
        assert_scenario_has_step(scenario, Checks::Backup::IncrementalParentType)
        assert_scenario_has_step(scenario, Procedures::Backup::AccessibilityConfirmation)
        assert_scenario_has_step(scenario, Procedures::Backup::PrepareDirectory)
        assert_scenario_has_step(scenario, Procedures::Backup::Metadata)
        assert_scenario_has_step(scenario, Procedures::Service::Stop) do |step|
          assert_empty(step.common_options[:only])
        end
        assert_scenario_has_step(scenario, Procedures::Backup::ConfigFiles)
        assert_scenario_has_step(scenario, Procedures::Backup::Pulp)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::CandlepinDB)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::ForemanDB)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::PulpcoreDB)
        assert_scenario_has_step(scenario, Procedures::Service::Start)
        assert_scenario_has_step(scenario, Procedures::Backup::CompressData)
      end
    end

    describe 'online' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Backup.new(:backup_dir => '.', :strategy => :online)
      end

      it 'composes all steps' do
        assert_scenario_has_step(scenario, Checks::Backup::IncrementalParentType)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::SafetyConfirmation)
        refute_scenario_has_step(scenario, Procedures::Backup::AccessibilityConfirmation)
        assert_scenario_has_step(scenario, Procedures::Backup::PrepareDirectory)
        assert_scenario_has_step(scenario, Procedures::Backup::Metadata)
        refute_scenario_has_step(scenario, Procedures::Service::Stop)
        assert_scenario_has_step(scenario, Procedures::Backup::ConfigFiles)
        assert_scenario_has_step(scenario, Procedures::Backup::Pulp)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::CandlepinDB)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::ForemanDB)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::PulpcoreDB)
        refute_scenario_has_step(scenario, Procedures::Service::Start)
        assert_scenario_has_step(scenario, Procedures::Backup::CompressData)
      end
    end
  end

  describe ForemanMaintain::Scenarios::BackupRescueCleanup do
    include DefinitionsTestHelper

    describe 'offline' do
      let(:scenario) do
        ForemanMaintain::Scenarios::BackupRescueCleanup.new(:backup_dir => '.',
          :strategy => :offline)
      end

      it 'composes all steps' do
        assert_scenario_has_step(scenario, Procedures::Service::Start)
        assert_scenario_has_step(scenario, Procedures::Backup::Clean)
      end
    end

    describe 'online' do
      let(:scenario) do
        ForemanMaintain::Scenarios::BackupRescueCleanup.new(:backup_dir => '.',
          :strategy => :online)
      end

      it 'composes all steps' do
        refute_scenario_has_step(scenario, Procedures::Service::Start)
        assert_scenario_has_step(scenario, Procedures::Backup::Clean)
      end
    end
  end
end
