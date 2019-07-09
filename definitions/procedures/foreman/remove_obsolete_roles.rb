module Procedures::Foreman
  class RemoveObsoleteRoles < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      description 'Remove obsolete roles that are not being used by any user or usergroup'
      confine do
        check_min_version('foreman', '1.11')
      end
    end

    def run
      duplicate_role_ids = feature(:foreman_database).query(
        Checks::Foreman::CheckDuplicateRoles.query_to_get_duplicate_roles
      ).map { |r| r['id'].to_i }
      remove_obsolete_role_records(duplicate_role_ids)
    end

    private

    def remove_obsolete_role_records(role_ids)
      feature(:foreman_database).psql(<<-SQL)
        BEGIN;
          DELETE from roles r where r.id IN (#{role_ids.join(', ')})
            AND r.id NOT IN (select role_id from user_roles);
        COMMIT;
      SQL
    end
  end
end
