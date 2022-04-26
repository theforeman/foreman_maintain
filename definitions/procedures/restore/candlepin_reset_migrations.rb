module Procedures::Restore
  class CandlepinResetMigrations < ForemanMaintain::Procedure
    metadata do
      description 'Ensure Candlepin runs all migrations after restoring the database'
      confine do
        feature(:candlepin_database)
      end
    end

    def run
      FileUtils.rm_f('/var/lib/candlepin/.puppet-candlepin-rpm-version')
    end
  end
end
