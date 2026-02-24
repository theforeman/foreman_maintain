module Report
  class SyncPlans < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to Katello sync plans'
      confine do
        feature(:katello)
      end
    end

    def run
      data_field('sync_plans_used') { sync_plans_used }
      data_field('sync_plans_count') { sync_plans_count }
    end

    private

    def sync_plans_used
      if table_exists('katello_sync_plans')
        sql_count('katello_sync_plans') > 0
      else
        false
      end
    end

    def sync_plans_count
      if table_exists('katello_sync_plans')
        sql_count('katello_sync_plans')
      else
        0
      end
    end
  end
end
