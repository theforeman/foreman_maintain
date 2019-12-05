module Procedures::Foreman
  class FixCorruptedRoles < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      desc = 'Create additional filters so that each filter has only permissions of one resource'
      description desc
      confine do
        check_min_version('foreman', '1.15')
      end
    end

    def run
      items = feature(:foreman_database).query(
        Checks::Foreman::CheckCorruptedRoles.inconsistent_filter_perms
      )
      items.group_by { |item| item['filter_id'] }.each_value do |filter_perm_data|
        inconsistent_sets = filter_perm_data.group_by { |perm_data| perm_data['resource_type'] }.
                            values
        find_records_to_update(inconsistent_sets).each do |set|
          update_records set
        end
      end
    end

    private

    def find_records_to_update(inconsistent_sets)
      largest_set = inconsistent_sets.reduce([]) do |memo, set|
        set.count > memo.count ? set : memo
      end

      inconsistent_sets.reject do |set|
        set == largest_set
      end
    end

    def update_records(set)
      new_filter = create_filter set.first['role_id'],
                                 set.first['search'],
                                 set.first['taxonomy_search'],
                                 set.first['override']
      set.each do |item|
        destroy_filtering item
        next if !new_filter || new_filter.empty?
        create_filtering item, new_filter
      end
    end

    def create_filter(role_id, search, taxonomy_search, override)
      feature(:foreman_database).query(
        create_filter_query(search, role_id, taxonomy_search, override)
      ).first
    end

    def escape_val(value)
      value ? "'#{value}'" : 'NULL'
    end

    def create_filter_query(search, role_id, taxonomy_search, override)
      <<-SQL
        WITH rows AS (
          INSERT INTO filters (search, role_id, taxonomy_search, override, created_at, updated_at)
          VALUES (#{escape_val(search)}, #{role_id}, #{escape_val(taxonomy_search)}, '#{override}', '#{Time.now}', '#{Time.now}')
          RETURNING id
          )
        SELECT id
        FROM rows
      SQL
    end

    def create_filtering(data, new_filter)
      feature(:foreman_database).query(
        create_filtering_query(data['permission_id'], new_filter['id'])
      )
    end

    def destroy_filtering(data)
      feature(:foreman_database).query(destroy_filtering_query(data['filtering_id']))
    end

    def destroy_filtering_query(filtering_id)
      <<-SQL
        WITH rows AS (
          DELETE FROM filterings
          WHERE id = #{filtering_id}
          RETURNING id
        )
        SELECT id
        FROM rows
      SQL
    end

    def create_filtering_query(permission_id, filter_id)
      <<-SQL
        WITH rows AS (
          INSERT INTO filterings (filter_id, permission_id, created_at, updated_at)
          VALUES (#{filter_id}, #{permission_id}, '#{Time.now}', '#{Time.now}')
          RETURNING id
        )
        SELECT id
        FROM rows
      SQL
    end
  end
end
