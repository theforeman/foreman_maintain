module Procedures::Pulp
  class Remove < ForemanMaintain::Procedure
    metadata do
      description 'Remove pulp2'
      param :assumeyes, 'Do not ask for confirmation', :default => false

      confine do
        check_min_version('katello-common', '4.0')
      end

      param :assume_yes, 'Run the full removal without asking.'
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
        '/var/lib/mongodb/',
        '/var/cache/pulp'
      ].select { |dir| File.directory?(dir) }
    end

    def pulp_data_dirs_mountpoints
      pulp_data_dirs.select { |d| Pathname(d).mountpoint? }
    end

    def deletable_pulp_dirs
      @deletable_pulp_dirs ||= pulp_data_dirs - pulp_data_dirs_mountpoints
    end

    # rubocop:disable  Metrics/MethodLength
    def pulp_packages
      possible = %w[pulp-admin-client pulp-agent pulp-consumer-client pulp-deb-admin-extensions
                    pulp-deb-plugins pulp-docker-admin-extensions pulp-docker-plugins
                    pulp-nodes-admin-extensions pulp-nodes-child pulp-nodes-common
                    pulp-nodes-consumer-extensions pulp-nodes-parent pulp-ostree-admin-extensions
                    pulp-ostree-plugins pulp-puppet-admin-extensions
                    pulp-puppet-consumer-extensions pulp-puppet-handlers pulp-puppet-plugins
                    pulp-puppet-tools pulp-python-admin-extensions pulp-python-plugins
                    pulp-rpm-admin-extensions pulp-rpm-consumer-extensions pulp-rpm-handlers
                    pulp-rpm-plugins pulp-rpm-yumplugins pulp-selinux pulp-server python-bson
                    python-crane python-isodate python-mongoengine python-nectar
                    python-pulp-agent-lib python-pulp-bindings python-pulp-client-lib
                    python-pulp-common python-pulp-deb-common python-pulp-devel
                    python-pulp-docker-common python-pulp-integrity python-pulp-manifest
                    python-pulp-oid_validation python-pulp-ostree-common python-pulp-puppet-common
                    python-pulp-python-common python-pulp-repoauth python-pulp-rpm-common
                    python-pulp-streamer python-pymongo python-pymongo-gridfs python2-amqp
                    python2-billiard python2-celery python2-debpkgr python2-django python2-kombu
                    python2-solv python2-vine pulp-katello pulp-maintenance
                    python3-pulp-2to3-migration]

      @installed_pulp_packages ||= possible.select { |pkg| find_package(pkg) }
      @installed_pulp_packages
    end

    def data_dir_removal_cmds(pulp_dirs)
      pulp_dirs.map { |dir| "rm -rf #{dir}" }
    end

    def ask_to_proceed
      rm_cmds = data_dir_removal_cmds(pulp_data_dirs)
      question = "\nWARNING: All pulp2 packages will be removed with the following commands:\n"
      question += "\n# rpm -e #{pulp_packages.join('  ')}" if pulp_packages.any?
      question += "\n# yum remove rh-mongodb34-*"
      question += "\n# yum remove squid mod_wsgi" \
        "\n\nAll pulp2 data will be removed.\n"
      question += rm_cmds.collect { |cmd| "\n# #{cmd}" }.join
      question += "\n\nDo you want to proceed?"
      answer = ask_decision(question, actions_msg: 'y(yes), q(quit)')
      abort! if answer != :yes
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes

      ask_to_proceed unless assumeyes_val

      remove_pulp if pulp_packages.any?

      remove_mongo

      remove_other_packages

      drop_migration_tables

      drop_migrations

      delete_pulp_data

      restart_pulpcore_services
    end

    def remove_pulp
      with_spinner('Removing pulp2 packages') do
        execute!("rpm -e #{pulp_packages.join('  ')}")
      end
    end

    def remove_mongo
      with_spinner('Removing mongo packages') do
        packages_action(:remove, ['rh-mongodb34-*'], :assumeyes => true)
      end
    end

    def remove_other_packages
      with_spinner('Removing additional packages') do
        packages_action(:remove, %w[squid mod_wsgi], :assumeyes => true)
      end
    end

    def drop_migration_tables
      with_spinner('Dropping migration tables') do
        feature(:pulpcore_database).psql(<<-SQL)
          BEGIN;
          DROP TABLE IF EXISTS pulp_2to3_migration_migrationplan,
            pulp_2to3_migration_pulp2blob,
            pulp_2to3_migration_pulp2content,
            pulp_2to3_migration_pulp2debcomponent,
            pulp_2to3_migration_pulp2debcomponentpackage,
            pulp_2to3_migration_pulp2debpackage,
            pulp_2to3_migration_pulp2debrelease,
            pulp_2to3_migration_pulp2debreleasearchitecture,
            pulp_2to3_migration_pulp2distribution,
            pulp_2to3_migration_pulp2distributor,
            pulp_2to3_migration_pulp2distributor_pulp2_repos,
            pulp_2to3_migration_pulp2erratum,
            pulp_2to3_migration_pulp2importer,
            pulp_2to3_migration_pulp2iso,
            pulp_2to3_migration_pulp2lazycatalog,
            pulp_2to3_migration_pulp2manifest,
            pulp_2to3_migration_pulp2manifestlist,
            pulp_2to3_migration_pulp2modulemd,
            pulp_2to3_migration_pulp2modulemddefaults,
            pulp_2to3_migration_pulp2packagecategory,
            pulp_2to3_migration_pulp2packageenvironment,
            pulp_2to3_migration_pulp2packagegroup,
            pulp_2to3_migration_pulp2packagelangpacks,
            pulp_2to3_migration_pulp2repocontent,
            pulp_2to3_migration_pulp2repository,
            pulp_2to3_migration_pulp2rpm,
            pulp_2to3_migration_pulp2srpm,
            pulp_2to3_migration_pulp2tag,
            pulp_2to3_migration_pulp2yumrepometadatafile,
            pulp_2to3_migration_reposetup CASCADE;
          DROP SEQUENCE IF EXISTS pulp_2to3_migration_pulp2distributor_pulp2_repos_id_seq;
          END;
        SQL
      end
    end

    def drop_migrations
      with_spinner('Dropping migrations') do
        feature(:pulpcore_database).psql(<<-SQL)
          BEGIN;
          DELETE FROM django_migrations WHERE app = 'pulp_2to3_migration';
          DELETE FROM auth_permission WHERE content_type_id in (SELECT id FROM django_content_type WHERE app_label = 'pulp_2to3_migration');
          DELETE FROM django_admin_log WHERE content_type_id in (SELECT id FROM django_content_type WHERE app_label = 'pulp_2to3_migration');
          DELETE FROM django_content_type WHERE app_label = 'pulp_2to3_migration';
          END;
        SQL
      end
    end
    # rubocop:enable Metrics/BlockLength

    def delete_pulp_data
      non_mountpoints = data_dir_removal_cmds(deletable_pulp_dirs)
      mountpoints = pulp_data_dirs_mountpoints
      with_spinner('') do |spinner|
        if non_mountpoints.any?
          spinner.update('Deleting pulp2 data directories.')
          non_mountpoints.each do |cmd|
            execute!(cmd)
          end
          msg_for_del_non_mountpoints(mountpoints, spinner)
        end
        if mountpoints.any?
          msg_for_del_mountpoints(mountpoints, spinner)
        end
      end
    end

    def msg_for_del_non_mountpoints(mountpoints, spinner)
      if mountpoints.empty?
        spinner.update('Done deleting all pulp2 data directories.')
      else
        spinner.update("Deleted: #{deletable_pulp_dirs.join("\n")}")
      end
    end

    def msg_for_del_mountpoints(mountpoints, spinner)
      _, cmd_name = ForemanMaintain.pkg_and_cmd_name
      if mountpoints.count > 1
        spinner.update("The directories #{mountpoints.join(',')} are individual mountpoints.")
        puts  "\nThe #{cmd_name} won't delete these directories.\n"\
              'You need to remove content and these directories on your own.'
      else
        spinner.update("The directory #{mountpoints.join(',')} is individual mountpoint.")
        puts  "\nThe #{cmd_name} won't delete the directory.\n"\
              'You need to remove content and the directory on your own.'
      end
    end

    def restart_pulpcore_services
      with_spinner('Restarting pulpcore services') do |spinner|
        pulp_services = feature(:pulpcore).services

        feature(:service).handle_services(spinner, 'stop', :only => pulp_services)
        feature(:service).handle_services(spinner, 'start', :only => pulp_services)
        spinner.update('Done restarting pulpcore services')
      end
    end
  end
end
