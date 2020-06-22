module Procedures::Restore
  class IncrementalConfirmation < ForemanMaintain::Procedure
    metadata do
      description 'Confirm incremental restore'
      tags :restore
    end

    def run
      warning = "\nWARNING: This script will start the restore process from " \
                "incremental data.\n" \
                "Once this operation is complete there is no going back.\n" \
                'Do you want to proceed?'
      answer = ask_decision(warning, 'y(yes), q(quit)')
      abort! unless answer == :yes
    end
  end
end
