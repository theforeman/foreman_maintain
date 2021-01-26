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
          "Do you want to proceed automatically?\n"
      answer = ask_decision(question, actions_msg: 'y(yes), n(no), q(quit)')
      abort! if answer == :quit

      with_spinner('Removing pulp') do |spinner|
        spinner.update('Stopping pulp2 services')
        pulp_services = %w[pulp_celerybeat pulp_workers pulp_resource_manager]
        feature(:service).handle_services(spinner, 'stop', :only => pulp_services)

        spinner.update('Removing pulp2 packages')
        packages_action(:remove, pulp_packages, :assumeyes => true)

      end

      pulp_data_dir_path = feature(:pulp2).data_dir
      if File.directory?(pulp_data_dir_path)
        question = '\nProceed with removal of pulp2 data directory?\n'
        rm_answer = ask_decision(question, actions_msg: 'y(yes), n(no), q(quit)')
        abort! if answer == :quit
        if rm_answer == :yes
          with_spinner('Deleting pulp2 data directory') do |spinner|
            execute!("rm -rf #{pulp_data_dir_path}")
            spinner.update 'Done deleting pulp2 data directory'
          end
        end
      end
    end
  end
end
