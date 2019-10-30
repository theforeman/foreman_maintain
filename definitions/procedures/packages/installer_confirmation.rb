module Procedures::Packages
  class InstallerConfirmation < ForemanMaintain::Procedure
    metadata do
      description 'Confirm installer run is allowed'
    end

    def run
      question = "\nWARNING: This script runs #{feature(:installer).installer_command} " \
        "after the yum execution \n" \
        "to ensure the #{feature(:instance).product_name} " \
        "is in a consistent state.\n" \
        "As a result some of your services may be restarted. \n\n" \
        'Do you want to proceed?'
      answer = ask_decision(question, 'y(yes), q(quit)')
      abort! unless answer == :yes
    end
  end
end
