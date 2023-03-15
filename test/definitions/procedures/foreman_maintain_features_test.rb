require 'test_helper'

describe Procedures::ForemanMaintainFeatures do
  include DefinitionsTestHelper

  subject do
    Procedures::ForemanMaintainFeatures.new
  end

  it 'lists features' do
    assume_feature_present(:hammer)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
    assert_includes result.output, 'hammer<Features::Hammer>'
  end
end
