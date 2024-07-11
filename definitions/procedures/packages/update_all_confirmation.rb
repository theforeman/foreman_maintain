module Procedures::Packages
  class UpdateAllConfirmation < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to update', :array => true

      description 'Confirm update all is intentional'
    end

    def run
      if @packages.nil? || @packages.empty?
        command = ForemanMaintain.command_name

        question = <<~MSG
          WARNING: No specific packages to update were provided
          so we are going to update all available packages. We
          recommend using the update command to update to a minor
          version and/or operating system using '#{command} update'.
          To upgrade to the next #{feature(:instance).product_name} version use '#{command} upgrade'.
          Do you want to proceed with update of everything regardless of
          the recommendations?
        MSG

        answer = ask_decision(question.strip, actions_msg: 'y(yes), q(quit)')
        abort! unless answer == :yes
      end
    end
  end
end
