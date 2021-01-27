module Procedures::Pulp
  class Remove < ForemanMaintain::Procedure

    metadata do
      description 'Remove pulp2'
      for_feature :pulp2
    end

    def pulp_packages
      [
       'pulp-server', 'python-pulp-streamer', 'pulp-puppet-plugins',
       'python-pulp-rpm-common', 'python-pulp-common',
       'pulp-selinux', 'python-pulp-oid_validation',
       'python-pulp-puppet-common', 'python-pulp-repoauth',
       'pulp-rpm-plugins'
      ]

    end

    def run
      question = "\nWARNING: All pulp2 packages will be removed.\n" \
          "All pulp2 data will be removed.\n" \
          "Do you want to proceed automatically? "
      answer_automatic = ask_decision(question, actions_msg: 'y(yes), n(no), q(quit)')
      abort! if answer_automatic == :quit

      assumeyes = true
      if answer_automatic == :no
        assumeyes = false
      end

      with_spinner('Removing pulp') do |spinner|
        spinner.update('Stopping pulp2 services')
        pulp_services = %w[pulp_celerybeat pulp_workers pulp_resource_manager]
        feature(:service).handle_services(spinner, 'stop', :only => pulp_services)

        spinner.update('Removing pulp2 packages')
      end

      pulp_packages.each do |package|
        remove_answer = :yes
        if answer_automatic == :no
          remove_question = "Remove #{package}? "
          remove_answer = ask_decision(remove_question, actions_msg: 'y(yes), n(no), q(quit)')
          abort! if remove_answer == :quit
        end
        packages_action(:remove, [package], :assumeyes => true) if remove_answer
      end
    end
  end
end
