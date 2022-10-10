require 'test_helper'

describe Checks::ForemanOpenscap::InvalidReportAssociations do
  include DefinitionsTestHelper

  subject do
    Checks::ForemanOpenscap::InvalidReportAssociations.new
  end

  it 'passes when no reports with association issues detected' do
    assume_feature_present(:foreman_openscap, :report_ids_without_host => [],
                                              :report_ids_without_proxy => [],
                                              :report_ids_without_policy => [])
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when some reports with association issues detected' do
    assume_feature_present(:foreman_openscap, :report_ids_without_host => [],
                                              :report_ids_without_proxy => [25],
                                              :report_ids_without_policy => [52])
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match 'There are 2 reports with issues that will be removed', result.output
    assert_equal [Procedures::ForemanOpenscap::InvalidReportAssociations],
      subject.next_steps.map(&:class)
  end
end
