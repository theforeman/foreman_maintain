module Procedures::Foreman
  class VacuumDatabase < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      advanced_run false
      description 'Reclaim some space used by a database'
    end

    def run
      execute("su - postgres -c 'vacuumdb --full --dbname=foreman'")
    end
  end
end
