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

      assume_feature_present(:pulpcore) do |feature|
        feature.any_instance.stubs(:configured_workers).returns([existing_pulpcore_worker])
      end

      assume_feature_present(:dynflow_sidekiq) do |feature|
        feature.any_instance.stubs(:workers).returns([existing_dynflow_worker])
      end
    end

    let(:existing_pulpcore_worker) { existing_system_service('pulpcore-worker@1', 10) }
    let(:existing_dynflow_worker) { existing_system_service('dynflow-sidekiq@worker-1', 10) }

    let(:task_checks) do
      [Checks::ForemanTasks::NotRunning,
       Checks::Pulpcore::NoRunningTasks]
    end

    let(:checks) do
      task_checks + [
        Checks::Foreman::DBIndex,
        Checks::Candlepin::DBIndex,
        Checks::Pulpcore::DBIndex,
      ]
    end

    describe 'offline' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Backup.new(:backup_dir => '.', :strategy => :offline)
      end

      it 'composes all steps' do
        task_checks.each do |check|
          assert_scenario_has_step(scenario, check) do |step|
            refute step.options['wait_for_tasks']
          end
        end
        checks.each do |check|
          assert_scenario_has_step(scenario, check)
        end
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

    describe 'offline with wait_for_tasks' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Backup.new(:backup_dir => '.', :strategy => :offline,
          :wait_for_tasks => true)
      end

      it 'composes all steps' do
        task_checks.each do |check|
          assert_scenario_has_step(scenario, check) do |step|
            assert step.options['wait_for_tasks']
          end
        end
      end
    end

    describe 'online' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Backup.new(:backup_dir => '.', :strategy => :online)
      end

      it 'composes all steps' do
        task_checks.each do |check|
          assert_scenario_has_step(scenario, check) do |step|
            refute step.options['wait_for_tasks']
          end
        end
        checks.each do |check|
          assert_scenario_has_step(scenario, check)
        end
        refute_scenario_has_step(scenario, Procedures::Backup::AccessibilityConfirmation)
        assert_scenario_has_step(scenario, Procedures::Backup::PrepareDirectory)
        assert_scenario_has_step(scenario, Procedures::Backup::Metadata)
        assert_scenario_has_step(scenario, Procedures::Service::Stop) do |step|
          assert_includes(step.common_options[:only], existing_pulpcore_worker)
          assert_includes(step.common_options[:only], existing_dynflow_worker)
          assert_equal(step.common_options[:only].length, 2)
        end
        assert_scenario_has_step(scenario, Procedures::Backup::ConfigFiles)
        assert_scenario_has_step(scenario, Procedures::Backup::Pulp)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::CandlepinDB)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::ForemanDB)
        assert_scenario_has_step(scenario, Procedures::Backup::Online::PulpcoreDB)
        assert_scenario_has_step(scenario, Procedures::Service::Start) do |step|
          assert_includes(step.common_options[:only], existing_pulpcore_worker)
          assert_includes(step.common_options[:only], existing_dynflow_worker)
          assert_equal(step.common_options[:only].length, 2)
        end
        assert_scenario_has_step(scenario, Procedures::Backup::CompressData)
      end
    end

    describe 'online with wait_for_tasks' do
      let(:scenario) do
        ForemanMaintain::Scenarios::Backup.new(:backup_dir => '.', :strategy => :online,
          :wait_for_tasks => true)
      end

      it 'composes all steps' do
        task_checks.each do |check|
          assert_scenario_has_step(scenario, check) do |step|
            assert step.options['wait_for_tasks']
          end
        end
      end
    end
  end

  describe ForemanMaintain::Scenarios::BackupRescueCleanup do
    include DefinitionsTestHelper

    before do
      assume_feature_present(:pulpcore) do |feature|
        feature.any_instance.stubs(:configured_workers).returns([existing_pulpcore_worker])
      end

      assume_feature_present(:dynflow_sidekiq) do |feature|
        feature.any_instance.stubs(:workers).returns([existing_dynflow_worker])
      end
    end

    let(:existing_pulpcore_worker) { existing_system_service('pulpcore-worker@1', 10) }
    let(:existing_dynflow_worker) { existing_system_service('dynflow-sidekiq@worker-1', 10) }

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
        assert_scenario_has_step(scenario, Procedures::Service::Start)
        assert_scenario_has_step(scenario, Procedures::Backup::Clean)
      end
    end
  end
end
