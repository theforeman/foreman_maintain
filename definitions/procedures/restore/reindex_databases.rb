module Procedures::Restore
  class ReindexDatabases < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemService

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
      end
    end
  end
end
