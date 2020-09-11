module Procedures::Foreman
  class VacuumDatabase < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      advanced_run false
      description 'Reclaim some space used by a database'
    end

    def run
      feature(:foreman_database).psql(<<-SQL)
        vacuum full verbose
      SQL
    end
  end
end
