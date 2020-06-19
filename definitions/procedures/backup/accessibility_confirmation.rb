module Procedures::Backup
  class AccessibilityConfirmation < ForemanMaintain::Procedure
    metadata do
      description 'Confirm turning off services is allowed'
      tags :backup
    end

    def run
      answer = ask_decision("WARNING: This script will stop your services.\n\n" \
         'Do you want to proceed?', actions_msg: 'y(yes), q(quit)')
      abort! unless answer == :yes
    end
  end
end
