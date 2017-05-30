class Features::SyncPlans < ForemanMaintain::Feature
  metadata do
    label :sync_plans
  end

  def active_sync_plans_count
    feature(:foreman_database).query(
      <<-SQL
        SELECT count(*) AS count FROM katello_sync_plans WHERE enabled ='t'
      SQL
    ).first['count'].to_i
  end

  def ids_by_status(enabled = true)
    enabled = enabled ? 't' : 'f'
    feature(:foreman_database).query(
      <<-SQL
        SELECT id FROM katello_sync_plans WHERE enabled ='#{enabled}'
      SQL
    ).map { |r| r['id'].to_i }
  end

  def disabled_plans_count
    data[:disabled].length
  end

  def make_disable(ids)
    update_records(ids, false)
  end

  def make_enable
    update_records(data[:disabled], true)
  end

  private

  def update_records(ids, enabled)
    updated_record_ids = []
    ids.each do |sp_id|
      result = hammer("sync-plan update --id #{sp_id} --enabled #{enabled}")
      if result.include?('Sync plan updated')
        updated_record_ids << sp_id
      else
        raise result
      end
    end
    updated_record_ids
  ensure
    new_data = sync_plan_data(enabled, updated_record_ids)
    save_state(new_data)
    updated_record_ids
  end

  def data
    upgrade_storage = ForemanMaintain.storage(:upgrade)
    @data ||= upgrade_storage.data.fetch(:sync_plans, :enabled => [], :disabled => [])
    @data
  end

  def sync_plan_data(enabled, new_ids)
    sync_plan_hash = data
    if enabled
      sync_plan_hash[:disabled] -= new_ids
      sync_plan_hash[:enabled] = new_ids
    else
      sync_plan_hash[:disabled].concat(new_ids)
    end
    sync_plan_hash
  end

  def save_state(sync_plan_hash = {})
    storage = ForemanMaintain.storage(:upgrade)
    storage[:sync_plans] = sync_plan_hash
    storage.save
  end
end
