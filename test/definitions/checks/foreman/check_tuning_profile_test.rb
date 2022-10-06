require 'test_helper'

describe Checks::Foreman::TuningRequirements do
  include DefinitionsTestHelper

  subject do
    Checks::Foreman::TuningRequirements.new
  end

  it 'passes when system memory and system cpu cores are greater than tuning profile' do
    assume_feature_present(:katello, query: [])
    assume_feature_present(:installer, configuration: { facts: { 'tuning' => 'default' } })

    subject.stubs(:cpu_cores).returns('6')
    subject.stubs(:memory).returns(24 * 1024 * 1024)
    result = run_check(subject)

    assert_equal 'true', result.output
  end

  it 'fails when system memory is less than tuning profile' do
    assume_feature_present(:katello, query: [])
    assume_feature_present(:installer, configuration: { facts: { 'tuning' => 'medium' } })

    subject.stubs(:cpu_cores).returns('24')
    subject.stubs(:memory).returns(24 * 1024 * 1024)
    result = run_check(subject)

    assert_includes result.output, 'The system memory is 24 GB but the currently configured tuning profile requires 32 GB.' # rubocop:disable Metrics/LineLength
    assert result.fail?
  end

  it 'fails when system CPU cores is less than tuning profile' do
    assume_feature_present(:katello, query: [])
    assume_feature_present(:installer, configuration: { facts: { 'tuning' => 'medium' } })

    subject.stubs(:cpu_cores).returns('6')
    subject.stubs(:memory).returns(42 * 1024 * 1024)
    result = run_check(subject)

    assert_includes result.output, 'The number of CPU cores for the system is 6 but the currently configured tuning profile requires 8.' # rubocop:disable Metrics/LineLength
    assert result.fail?
  end
end
