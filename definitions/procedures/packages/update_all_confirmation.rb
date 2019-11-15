module Procedures::Packages
  class UpdateAllConfirmation < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to update', :array => true

      description 'Confirm update all is intentional'
    end

    def run
      if @packages.nil? || @packages.empty?
        question = "\nWARNING: No specific packages to update were provided\n" \
          "so we are going to update all available packages.\n" \
          "It is recommended to update everything only as part of upgrade\n" \
          "of the #{feature(:instance).product_name} to the next version. \n" \
          "To Upgrade to next version use 'foreman-maintain upgrade'.\n\n" \
          "NOTE: --assumeyes is not applicable for this check\n\n" \
          "Do you want to proceed with update of everything regardless\n" \
          'of the recommendations?'
        answer = ask_decision(question, 'y(yes), q(quit)', ignore_assumeyes: true)
        abort! unless answer == :yes
      end
    end
  end
end
