require 'test_helper'
require_relative '../../test_helper'
require_relative '../../../../definitions/procedures/packages/update_all_confirmation'

describe Procedures::Packages::UpdateAllConfirmation do
  include ::DefinitionsTestHelper

  def skip_mock_package_manager
    true
  end

  subject do
    Procedures::Packages::UpdateAllConfirmation.new
  end

  it 'contains the proper message for Foreman' do
    assume_feature_present(:foreman_install)

    question = <<~MSG
      WARNING: No specific packages to update were provided
      so we are going to update all available packages. We
      recommend using the update command to update to a minor
      version and/or operating system using 'foreman-maintain update'.
      To upgrade to the next Foreman version use 'foreman-maintain upgrade'.
      Do you want to proceed with update of everything regardless of
      the recommendations?
      , [y(yes), q(quit)]
    MSG

    answer = run_procedure(subject)
    assert_equal answer.reporter.output, question
  end

  it 'contains the proper message for Satellite' do
    assume_feature_present(:satellite)

    question = <<~MSG
      WARNING: No specific packages to update were provided
      so we are going to update all available packages. We
      recommend using the update command to update to a minor
      version and/or operating system using 'satellite-maintain update'.
      To upgrade to the next Satellite version use 'satellite-maintain upgrade'.
      Do you want to proceed with update of everything regardless of
      the recommendations?
      , [y(yes), q(quit)]
    MSG

    answer = run_procedure(subject)
    assert_equal answer.reporter.output, question
  end
end
