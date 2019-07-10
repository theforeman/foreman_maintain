module Procedures::Foreman
  class RemoveDuplicateObsoleteRoles < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      description 'Remove duplicate obsolete roles from DB'
      confine do
        check_min_version('foreman', '1.11')
      end
    end

    def run
      duplicate_roles = feature(:foreman_database).query(
        Checks::Foreman::CheckDuplicateRoles.query_to_get_duplicate_roles
      )
      roles_hash = duplicate_roles.each_with_object({}) do |role_rec, new_obj|
        r_name = role_rec['name']
        new_obj[r_name] = [] unless new_obj.key?(r_name)
        new_obj[r_name] << role_rec['id'].to_i
      end
      duplicate_role_ids = filter_consumed_roles(roles_hash)
      remove_obsolete_role_records(duplicate_role_ids)
    end

    private

    def filter_consumed_roles(roles_hash)
      consumed_role_ids = find_consumed_role_ids
      roles_hash.values.map do |ids|
        if !(consumed_ids = (ids & consumed_role_ids)).empty?
          ids -= consumed_ids
        elsif ids.length > 1
          ids.delete(ids.min)
        end
        ids
      end.flatten
    end

    def find_consumed_role_ids
      feature(:foreman_database).query(<<-SQL).map { |r| r['role_id'].to_i }
       select DISTINCT(role_id) role_id from user_roles
      SQL
    end

    def remove_obsolete_role_records(role_ids)
      feature(:foreman_database).psql(<<-SQL)
        BEGIN;
          DELETE from roles r where r.id IN (#{role_ids.join(', ')});
        COMMIT;
      SQL
    end
  end
end
