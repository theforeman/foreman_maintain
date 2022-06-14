module Procedures::Content
  class Switchover < ForemanMaintain::Procedure
    metadata do
      description 'Switch support for certain content from Pulp 2 to Pulp 3'
      for_feature :pulpcore

      confine do
        !check_min_version(foreman_plugin_name('katello'), '4.0')
      end

      param :skip_deb, 'Do not run debian options in installer.'
      do_not_whitelist
    end

    def run
      puts 'Performing final content migration before switching content'
      puts execute!('foreman-rake katello:pulp3_migration')
      puts 'Performing a check to verify everything that is needed has been migrated'
      puts execute!('foreman-rake katello:pulp3_post_migration_check')
      puts 'Switching specified content over to pulp 3'
      puts execute!('foreman-rake katello:pulp3_content_switchover')
      run_installer if feature(:katello_install)
    end

    def run_installer
      puts 'Re-running the installer to switch specified content over to pulp3'
      args = ['--foreman-proxy-content-proxy-pulp-isos-to-pulpcore=true',
              '--foreman-proxy-content-proxy-pulp-yum-to-pulpcore=true',
              '--katello-use-pulp-2-for-file=false',
              '--katello-use-pulp-2-for-docker=false',
              '--katello-use-pulp-2-for-yum=false']

      unless @skip_deb
        args += ['--katello-use-pulp-2-for-deb=false',
                 '--foreman-proxy-content-proxy-pulp-deb-to-pulpcore=true']
      end

      feature(:installer).run(args.join(' '))
    end
  end
end
