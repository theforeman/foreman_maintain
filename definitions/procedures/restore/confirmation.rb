module Procedures::Restore
  class Confirmation < ForemanMaintain::Procedure
    metadata do
      description 'Confirm dropping databases and running restore'
      tags :restore
    end

    def run
      warning = "\nWARNING: This script will drop and restore your database.\n" \
                "Your existing installation will be replaced with the backup database.\n" \
                "Once this operation is complete there is no going back.\n" \
                'Do you want to proceed?'
      answer = ask_decision(warning, actions_msg: 'y(yes), q(quit)')
      abort! unless answer == :yes
    end
  end
end
