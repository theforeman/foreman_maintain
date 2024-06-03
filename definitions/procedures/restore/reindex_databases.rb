module Procedures::Restore
  class ReindexDatabases < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemService
    include ForemanMaintain::Concerns::SystemHelpers

    metadata do
      description 'REINDEX databases'

      confine do
        feature(:instance).postgresql_local?
      end
    end

    def run
      with_spinner('Reindexing the databases') do |spinner|
        feature(:service).handle_services(spinner, 'start', :only => ['postgresql'])

        spinner.update('Reindexing the databases')
        execute!('runuser - postgres -c "reindexdb -a"')
        if check_min_version('python3.11-pulp-ansible', '0.20.0')
          execute!('runuser -c '\
                   '\'echo "ALTER COLLATION pulp_ansible_semver REFRESH VERSION;"'\
                   '| psql pulpcore\' postgres')
        end
      end
    end
  end
end
