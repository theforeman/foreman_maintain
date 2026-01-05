require 'test_helper'

describe Checks::CheckSubscriptionManagerRelease do
  include DefinitionsTestHelper

  subject { Checks::CheckSubscriptionManagerRelease.new }

  before do
    assume_feature_present(:satellite)
  end

  it 'succeeds when release is not set' do
    subject.expects(:execute_with_status).with('LC_ALL=C subscription-manager release --show').
      returns([
                0, 'Release not set'
              ])
    result = run_step(subject)

    assert result.success?
  end

  it 'succeeds when release is set to a major version' do
    subject.expects(:execute_with_status).with('LC_ALL=C subscription-manager release --show').
      returns([0, 'Release: 9'])
    result = run_step(subject)

    assert result.success?
  end

  it 'fails when release is set to a minor version' do
    subject.expects(:execute_with_status).with('LC_ALL=C subscription-manager release --show').
      returns([0, 'Release: 9.5'])
    result = run_step(subject)

    assert result.fail?
    assert_match(/Your system is configured to use RHEL 9\.5/, result.output)
    assert_match(/subscription-manager release --unset/, result.output)
  end

  it 'succeeds when subscription-manager is not installed or system is not registered' do
    subject.expects(:execute_with_status).with('LC_ALL=C subscription-manager release --show').
      returns([1, 'This system is not yet registered.'])
    result = run_step(subject)

    assert result.success?
  end
end
