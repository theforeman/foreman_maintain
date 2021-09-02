class Checks::CheckForNewerPackages < ForemanMaintain::Check
  metadata do
    label :check_for_newer_packages
    description 'Check for newer packages and optionally ask for confirmation if not found.'

    param :packages,
          'package names to validate',
          :required => true
    param :manual_confirmation_version,
          'Version of satellite (6.9) to ask the user if they are on the latest minor release of.',
          :required => false
  end

  def run
    exit_status, = ForemanMaintain.package_manager.check_update(packages: @packages,
                                                                with_status: true)
    assert(exit_status == 0, 'An update is available for one of these packages: '\
                "#{@packages.join(',')}. Please update before proceeding.")
    if @manual_confirmation_version
      question = 'Confirm that you are running the latest minor release of Satellite '\
                "#{@manual_confirmation_version}"
      answer = ask_decision(question, actions_msg: 'y(yes), q(quit)')
      abort! if answer != :yes
    end
  end
end
