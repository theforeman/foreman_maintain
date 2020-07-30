module Procedures::Foreman
  class RemoveDuplicatePermissions < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      description 'Remove duplicate permissions from DB'
    end

    # rubocop:disable Metrics/MethodLength
    def run
      duplicate_permissions = feature(:foreman_database).query(
        Checks::Foreman::CheckDuplicatePermission.query_to_get_duplicate_permission
      )
      duplicate_permissions.each do |permission|
        assigned_permissions = []
        ids = feature(:foreman_database).query(query_to_get_permission_ids(permission)).
              flat_map(&:values)
        ids.each do |permission_id|
          filterings = feature(:foreman_database).
                       query(query_to_check_permission_assign_to_filter(permission_id))
          if filterings.empty?
            delete_permission(permission_id)
          else
            assigned_permissions << permission_id
          end
        end
        if assigned_permissions.length > 1
          fix_permissions(assigned_permissions)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def fix_permissions(assigned_permissions)
      persist_permission = assigned_permissions.shift
      assigned_permissions.each do |permission|
        update_filtering(permission, persist_permission)
        delete_permission(permission)
      end
    end

    def update_filtering(old_id, new_id)
      sql = <<-SQL
      WITH rows AS (
        UPDATE filterings SET permission_id = '#{new_id}' WHERE permission_id = '#{old_id}'
        RETURNING id
      )
      SELECT id
      FROM rows
      SQL

      feature(:foreman_database).query(sql)
    end

    def delete_permission(permission_id)
      sql = <<-SQL
      WITH rows AS (
        DELETE FROM permissions where id = '#{permission_id}' RETURNING id
      )
      SELECT id
      FROM rows
      SQL

      feature(:foreman_database).query(sql)
    end

    def query_to_get_permission_ids(permission)
      <<-SQL
        SELECT id FROM permissions where name = '#{permission['name']}' and resource_type = '#{permission['resource_type']}'
      SQL
    end

    def query_to_check_permission_assign_to_filter(permission_id)
      <<-SQL
        SELECT id, filter_id FROM filterings WHERE permission_id = '#{permission_id}'
      SQL
    end
  end
end
