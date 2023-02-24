class Features::SyncPlans < ForemanMaintain::Feature
  metadata do
    label :sync_plans
  end

  def sync_plan_ids_by_status(enabled = true)
    query = <<-SQL
      select sp.id as id from katello_sync_plans sp inner join foreman_tasks_recurring_logics rl on sp.foreman_tasks_recurring_logic_id = rl.id
      where rl.state='#{enabled ? 'active' : 'disabled'}'
    SQL
    feature(:foreman_database).query(query).map { |r| r['id'].to_i }
  end

  def validate_sync_plan_ids(ids)
    return [] if ids.empty?

    ids_condition = ids.map { |id| "'#{id}'" }.join(',')
    query = "SELECT id FROM katello_sync_plans WHERE id IN (#{ids_condition})"
    feature(:foreman_database).query(query).map { |r| r['id'].to_i }
  end

  def make_disable
    cleanup_enabled_in_storage
    update_records(sync_plan_ids_by_status(true), false)
    @data[:disabled]
  end

  def make_enable
    # remove ids of sync plans which no longer exist in DB
    @data[:disabled] = validate_sync_plan_ids(@data[:disabled])
    update_records(@data[:disabled], true)
    @data[:enabled]
  end

  def load_from_storage(storage)
    @data = storage.data.fetch(:sync_plans, :enabled => [], :disabled => [])
  end

  def save_to_storage(storage)
    storage[:sync_plans] = @data
  end

  def status_for_maintenance_mode(mode_on)
    default_storage = ForemanMaintain.storage(:default)
    load_from_storage(default_storage)
    return ['sync plans: empty data', []] if both_empty?

    if @data[:enabled] && key_empty?(:disabled)
      [
        'sync plans: enabled',
        mode_on ? [Procedures::SyncPlans::Disable.new] : []
      ]
    else
      [
        'sync plans: disabled',
        mode_on ? [] : [Procedures::SyncPlans::Enable.new]
      ]
    end
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
  ensure
    update_data(enabled, updated_record_ids)
  end

  def data
    raise 'Use load_from_storage before accessing the data' unless defined? @data
    @data
  end

  def cleanup_enabled_in_storage
    @data[:enabled] = []
  end

  def update_data(enabled, new_ids)
    # init data
    @data[:disabled] = [] unless @data[:disabled]
    @data[:enabled] = [] unless @data[:enabled]

    if enabled
      @data[:disabled] -= new_ids
      @data[:enabled].concat(new_ids).uniq!
    else
      @data[:enabled] -= new_ids
      @data[:disabled].concat(new_ids).uniq!
    end
  end

  def both_empty?
    key_empty?(:disabled) && key_empty?(:enabled)
  end

  def key_empty?(key_name)
    (@data[key_name].nil? || @data[key_name] && @data[key_name].empty?)
  end
end
