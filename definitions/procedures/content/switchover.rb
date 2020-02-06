module Procedures::Content
  class Switchover < ForemanMaintain::Procedure
    metadata do
      description 'Switch support for certain content from Pulp 2 to Pulp 3'
      for_feature :pulpcore
    end

    def run
      execute!('foreman-rake katello:pulp3_migration')
      execute!('foreman-rake katello:pulp3_post_migration_check')
      execute!('foreman-rake katello:pulp3_content_switchover')
      args = ['--foreman-proxy-content-proxy-pulp-isos-to-pulpcore=true',
              '--katello-use-pulp-2-for-file=false',
              '--katello-use-pulp-2-for-docker=false']
      feature(:installer).run(args.join(' '))
    end
  end
end
