module Procedures::Content
  class Switchover < ForemanMaintain::Procedure
    metadata do
      description 'Switch support for certain content from Pulp 2 to Pulp 3'
      for_feature :pulpcore

      confine do
        # FIXME: remove this condition on next downstream upgrade scenario
        !feature(:instance).downstream
      end
    end

    def run
      puts 'Performing final content migration before switching content'
      puts execute!('foreman-rake katello:pulp3_migration')
      puts 'Performing a check to verify everything that is needed has been migrated'
      puts execute!('foreman-rake katello:pulp3_post_migration_check')
      puts 'Switching specified content over to pulp 3'
      puts execute!('foreman-rake katello:pulp3_content_switchover')
      puts 'Re-running the installer to switch specified content over to pulp3'
      args = ['--foreman-proxy-content-proxy-pulp-isos-to-pulpcore=true',
              '--katello-use-pulp-2-for-file=false',
              '--katello-use-pulp-2-for-docker=false',
              '--katello-use-pulp-2-for-yum=false']
      feature(:installer).run(args.join(' '))
    end
  end
end
