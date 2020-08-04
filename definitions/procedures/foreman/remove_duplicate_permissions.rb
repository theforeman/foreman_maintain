module Procedures::Foreman
  class RemoveDuplicatePermissions < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      description 'Remove duplicate permissions from database'
    end

    def run
      duplicate_permissions = feature(:foreman_database).query(
        Checks::Foreman::CheckDuplicatePermissions.query_to_get_duplicate_permission
      ).group_by { |permission| permission['name'] }
      unassigned_permissions = []
      duplicate_permissions.each_value do |permissions|
        permission_ids = permissions.map { |i| i['id'] }
        filterings = check_permissions_assign_to_filter(permission_ids)
        assigned_permissions = filterings.keys
        unassigned_permissions << permission_ids - assigned_permissions
        fix_permissions(assigned_permissions) if assigned_permissions.length > 1
      end
      delete_permission(unassigned_permissions.flatten) unless unassigned_permissions.empty?
    end

    private

    def check_permissions_assign_to_filter(permission_ids)
      sql = <<-SQL
        SELECT id, filter_id, permission_id FROM filterings WHERE permission_id IN (#{permission_ids.join(',')})
      SQL
      feature(:foreman_database).query(sql).group_by { |filtering| filtering['permission_id'] }
    end

    def fix_permissions(assigned_permissions)
      persist_permission = assigned_permissions.shift
      update_filtering(assigned_permissions, persist_permission)
      delete_permission(assigned_permissions)
    end

    def update_filtering(old_ids, new_id)
      sql = <<-SQL
      WITH rows AS (
        UPDATE filterings SET permission_id = '#{new_id}' WHERE permission_id IN (#{old_ids.join(',')})
        RETURNING id
      )
      SELECT id
      FROM rows
      SQL

      feature(:foreman_database).query(sql)
    end

    def delete_permission(permission_ids)
      sql = <<-SQL
      WITH rows AS (
        DELETE FROM permissions where id IN (#{permission_ids.join(',')}) RETURNING id
      )
      SELECT id
      FROM rows
      SQL

      feature(:foreman_database).query(sql)
    end
  end
end
