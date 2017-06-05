module Procedures::Upgrade
  class PreMigration < ForemanMaintain::Procedure
    metadata do
      tags :pre_migrations
    end

    def run
      error!('fail') if TestHelper.migrations_fail_at == :pre_migrations
    end
  end

  class Migration < ForemanMaintain::Procedure
    metadata do
      tags :migrations
    end

    def run
      error!('fail') if TestHelper.migrations_fail_at == :migrations
    end
  end

  class PostMigration < ForemanMaintain::Procedure
    metadata do
      tags :post_migrations
    end

    def run
      error!('fail') if TestHelper.migrations_fail_at == :post_migrations
    end
  end

  class PostUpgradeCheck < ForemanMaintain::Check
    metadata do
      tags :post_upgrade_checks
    end

    def run
      error!('fail') if TestHelper.migrations_fail_at == :post_upgrade_checks
    end
  end
end
