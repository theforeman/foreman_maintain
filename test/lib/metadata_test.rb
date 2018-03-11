require 'test_helper'

module ForemanMaintain
  module Concerns
    describe Metadata do
      it 'depending upon direct_invocation, it allows procedure to run using advanced command' do
        procedures = ForemanMaintain.allowed_available_procedures(nil)
        assert_includes(procedures, Procedures::Setup,
                        'procedure is missing')
        refute_includes(procedures, Procedures::AdvancedRunNotAllowed,
                        'procedures that should not be found are present')
      end
    end
  end
end
