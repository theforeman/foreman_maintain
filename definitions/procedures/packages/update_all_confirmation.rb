module Procedures::Packages
  class UpdateAllConfirmation < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to update', :array => true

      description 'Confirm update all is intentionall'
    end

    def run
      if @packages.nil? or @packages.empty?
        question = "\nWARNING: No speciffic packages to update were provided " \
          "so we are going to update all available packages.\n" \
          "It is recommended to update everything only as part of " \
          "upgrade of the #{feature(:instance).product_name} to the next version. \n" \
          "To Upgrade to next version use 'foreman-maintain upgrade'.\n\n" \
          'Do you want to proceed with update of everything regardless of the recommendations?'
        answer = ask_decision(question, 'y(yes), q(quit)')
        abort! unless answer == :yes
      end
    end
  end
end
