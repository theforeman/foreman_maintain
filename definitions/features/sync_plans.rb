class Features::SyncPlans < ForemanMaintain::Feature
  metadata do
    label :sync_plans
  end

  def required_new_implementation
    @required_new_implementation ||=
      feature(:foreman_database).query(
        <<-SQL
          SELECT COUNT(1) FROM information_schema.table_constraints
          WHERE constraint_name='katello_sync_plan_foreman_tasks_recurring_logic_fk' AND table_name='katello_sync_plans'
        SQL
      ).first['count'].to_i > 0
  end

  def sync_plan_ids_by_status(enabled = true, filter_ids = nil)
    if filter_ids
      return [] if filter_ids.empty?

      ids_condition = filter_ids.map { |id| "'#{id}'" }.join(',')
    end

    if required_new_implementation
      query = <<-SQL
        select sp.id as id from katello_sync_plans sp inner join foreman_tasks_recurring_logics rl on sp.foreman_tasks_recurring_logic_id = rl.id
        where rl.state='#{enabled ? 'active' : 'disabled'}' #{ids_condition ? " AND sp.id IN (#{ids_condition})" : ''}
      SQL
    else
      query = <<-SQL
        SELECT id FROM katello_sync_plans WHERE enabled ='#{enabled ? 't' : 'f'}' #{ids_condition ? " AND id IN (#{ids_condition})" : ''}
      SQL
    end
    feature(:foreman_database).query(query).map { |r| r['id'].to_i }
  end

  def validate_sync_plan_ids(ids)
    return [] if ids.empty?

    ids_condition = ids.map { |id| "'#{id}'" }.join(',')
    query = "SELECT id FROM katello_sync_plans WHERE id IN (#{ids_condition})"
    feature(:foreman_database).query(query).map { |r| r['id'].to_i }
  end

  def make_disable(ids)
    update_records(ids, false)
  end

  def make_enable
    # remove ids of sync plans which no longer exist in DB
    @data[:disabled] = validate_sync_plan_ids(@data[:disabled])
    update_records(@data[:disabled], true)
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
    ids_not_required_update = sync_plan_ids_by_status(enabled, ids)
    ids_required_update = ids - ids_not_required_update
    make_data_key_empty(enabled) if !ids_not_required_update.empty? && ids_required_update.empty?
    updated_record_ids = []
    ids_required_update.each do |sp_id|
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

  def make_data_key_empty(enabled)
    key_name = enabled ? 'disabled' : 'enabled'
    @data[:"#{key_name}"] = []
  end

  def update_data(enabled, new_ids)
    if enabled
      @data[:disabled] -= new_ids
      @data[:enabled] = new_ids
    else
      @data[:disabled] = [] unless @data[:disabled]
      @data[:enabled] = [] if @data[:disabled].empty?
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
