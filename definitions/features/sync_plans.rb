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

  def make_disable(ids)
    update_records(ids, false)
  end

  def make_enable
    update_records(data[:disabled], true)
  end

  def load_from_storage(storage)
    @data = storage.data.fetch(:sync_plans, :enabled => [], :disabled => [])
  end

  def save_to_storage(storage)
    storage[:sync_plans] = @data
  end

  def maintenance_mode?
    default_storage = ForemanMaintain.storage(:default)
    load_from_storage(default_storage)
    return nil if both_empty?
    return 0 if @data[:enabled] && key_empty?(:disabled)
    1
  end

  private

  def update_records(ids, enabled)
    updated_record_ids = []
    ids.each do |sp_id|
      result = feature(:hammer).run("sync-plan update --id #{sp_id} --enabled #{enabled}")
      if result.include?('Sync plan updated')
        updated_record_ids << sp_id
      else
        raise result
      end
    end
    updated_record_ids
  ensure
    update_data(enabled, updated_record_ids)
  end

  def data
    raise 'Use load_from_storage before accessing the data' unless defined? @data
    @data
  end

  def update_data(enabled, new_ids)
    if enabled
      @data[:disabled] -= new_ids
      @data[:enabled] = new_ids
    else
      @data[:disabled] = [] unless @data[:disabled]
      @data[:disabled].concat(new_ids)
    end
  end

  def both_empty?
    key_empty?(:disabled) && key_empty?(:enabled)
  end

  def key_empty?(key_name)
    (@data[key_name].nil? || @data[key_name] && @data[key_name].empty?)
  end
end
