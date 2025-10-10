module Checks
  class DBUpCheck < ForemanMaintain::Check
    def run
      status = false
      if feature(database_feature).psql_cmd_available?
        with_spinner("Checking connection to the #{database_name} DB") do
          status = feature(database_feature).ping
        end
        assert(status, "#{database_name} DB is not responding. " \
          "It needs to be up and running to perform the following steps",
          :next_steps => start_pgsql)
      else
        feature(database_feature).raise_psql_missing_error
      end
    end

    def start_pgsql
      if feature(database_feature).local?
        [Procedures::Service::Start.new(:only => 'postgresql')]
      else
        [] # there is nothing we can do for remote db
      end
    end

    def database_feature
      raise NotImplementedError, 'Subclasses must define `database_feature`'
    end

    def database_name
      raise NotImplementedError, 'Subclasses must define `database_name`'
    end
  end
end
