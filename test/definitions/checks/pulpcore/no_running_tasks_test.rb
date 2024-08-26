require 'test_helper'

describe Checks::Pulpcore::NoRunningTasks do
  include DefinitionsTestHelper

  context 'with default params' do
    subject do
      Checks::Pulpcore::NoRunningTasks.new
    end

    it 'passes when no cli is installed' do
      assume_feature_present(:pulpcore, :running_tasks => []) do |feature|
        feature.any_instance.stubs(:cli_available?).returns(false)
      end
      result = run_check(subject)
      assert result.success?, 'Check expected to succeed'
    end

    it 'passes when not active tasks are present' do
      assume_feature_present(:pulpcore, :running_tasks => []) do |feature|
        feature.any_instance.stubs(:cli_available?).returns(true)
      end
      result = run_check(subject)
      assert result.success?, 'Check expected to succeed'
    end

    it 'fails when running/paused tasks are present' do
      assume_feature_present(:pulpcore, :running_tasks => ['a_task']) do |feature|
        feature.any_instance.stubs(:cli_available?).returns(true)
      end
      result = run_check(subject)
      assert result.fail?, 'Check expected to fail'
      msg = 'There are 1 active task(s) in the system.'
      msg += "\nPlease wait for these to complete."
      assert_match msg, result.output
      assert_empty subject.next_steps.map(&:class)
    end
  end

  context 'with wait_for_tasks=>true' do
    subject do
      Checks::Pulpcore::NoRunningTasks.new(:wait_for_tasks => true)
    end

    it 'passes when not active tasks are present' do
      assume_feature_present(:pulpcore, :running_tasks => []) do |feature|
        feature.any_instance.stubs(:cli_available?).returns(true)
      end
      result = run_check(subject)
      assert result.success?, 'Check expected to succeed'
    end

    it 'fails when running/paused tasks are present' do
      assume_feature_present(:pulpcore, :running_tasks => ['a_task']) do |feature|
        feature.any_instance.stubs(:cli_available?).returns(true)
      end
      result = run_check(subject)
      assert result.fail?, 'Check expected to fail'
      msg = 'There are 1 active task(s) in the system.'
      msg += "\nPlease wait for these to complete."
      assert_match msg, result.output
      assert_equal [Procedures::Pulpcore::WaitForTasks],
        subject.next_steps.map(&:class)
    end
  end
end
