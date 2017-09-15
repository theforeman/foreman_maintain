require 'test_helper'

describe Checks::HammerPing do
  include DefinitionsTestHelper

  subject do
    Checks::HammerPing.new
  end

  it 'passes when all services are running' do
    assume_feature_present(:hammer, :hammer_ping_cmd => hammer_ping_result_for_success)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when any of the service is not running' do
    assume_feature_present(:hammer, :hammer_ping_cmd => hammer_ping_result_for_fail)
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    error_msg = 'foreman_tasks resource(s) are failing.'
    assert_match error_msg, result.output
    assert_equal [Procedures::KatelloService::Restart], subject.next_steps.map(&:class)
  end

  def hammer_ping_result_for_success
    {
      :success => true,
      :message => '',
      :data => []
    }
  end

  def hammer_ping_result_for_fail
    {
      :success => false,
      :message => 'foreman_tasks resource(s) are failing.',
      :data => ['foreman_tasks']
    }
  end
end
