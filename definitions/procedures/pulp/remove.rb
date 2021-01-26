module Procedures::Pulp
  class Remove < ForemanMaintain::Procedure
    metadata do
      description 'Remove pulp2'

      confine do
        check_min_version('katello-common', '4.0')
      end
    end

    def sys
      ForemanMaintain::Utils::SystemHelpers.new
    end

    def pulp_data_dirs
      [
        '/var/lib/pulp/published',
        '/var/lib/pulp/content',
        '/var/lib/pulp/importers',
        '/var/lib/pulp/uploads',
        '/var/lib/mongodb/'
      ]
    end

    def pulp_packages
      [
        'pulp-server', 'python-pulp-streamer', 'pulp-puppet-plugins',
        'python-pulp-rpm-common', 'python-pulp-common',
        'pulp-selinux', 'python-pulp-oid_validation',
        'python-pulp-puppet-common', 'python-pulp-repoauth',
        'pulp-rpm-plugins', 'python-blinker', 'python-celery',
        'python-django', 'python-isodate', 'python-ldap',
        'python-mongoengine', 'python-nectar', 'python-oauth2',
        'python-pymongo'
      ]
    end

    def data_dir_removal_cmds
      pulp_data_dirs.collect { |dir| "rm -rf #{dir}" }
    end

    def ask_to_proceed(rm_cmds)
      question = "\nWARNING: All pulp2 packages will be removed with the following commands:\n" \
        "\n# yum remove #{pulp_packages.join('  ')}" \
        "\n# yum remove rh-mongodb34-*" \
        "\n\nAll pulp2 data will be removed.\n"
      question += rm_cmds.collect { |cmd| "\n# #{cmd}" }.join
      question += "\n\nDo you want to proceed?"
      answer = ask_decision(question, actions_msg: 'y(yes), q(quit)')
      abort! if answer != :yes
    end

    def run
      rm_cmds = data_dir_removal_cmds
      ask_to_proceed(rm_cmds)

      remove_pulp

      remove_mongo

      delete_pulp_data(rm_cmds)
    end

    def remove_pulp
      with_spinner('Removing pulp2 packages') do
        packages_action(:remove, pulp_packages, :assumeyes => true)
      end
    end

    def remove_mongo
      with_spinner('Removing mongo packages') do
        packages_action(:remove, ['rh-mongodb34-*'], :assumeyes => true)
      end
    end

    def delete_pulp_data(rm_cmds)
      with_spinner('Deleting pulp2 data directories') do |spinner|
        rm_cmds.each do |cmd|
          if File.directory?(cmd.split[2])
            execute!(cmd)
          end
        end
        spinner.update('Done deleting pulp2 data directories')
      end
    end
  end
end
