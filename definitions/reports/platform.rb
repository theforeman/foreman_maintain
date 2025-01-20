module Reports
  class Platform < ForemanMaintain::Report
    metadata do
      description 'Report about platform usages'
    end

    def run
      general_fields
      rbac_fields
      settings_fields
      bookmarks_fields
      mail_notification_fields
      user_groups_fields
    end

    def mail_notification_fields
      # Mail notifications
      # users_per_mail_notification =
      #   feature(:foreman_database).
      #   query(
      #     <<-SQL
      #       select
      #         max(mail_notifications.name) as notification_name,
      #         count(user_mail_notifications.user_id)
      #       from user_mail_notifications inner join mail_notifications
      #         on mail_notification_id = mail_notifications.id
      #       group by mail_notification_id
      #     SQL
      #   ).
      #   to_h { |row| [row['notification_name'], row['count'].to_i] }

      data_field('user_mail_notifications_count') { sql_count('user_mail_notifications') }
    end

    def user_groups_fields
      data_field('user_groups_count') { sql_count('usergroups') }
    end

    def general_fields
      data_field('smart_proxies_count') { sql_count('smart_proxies') }
      merge_data('smart_proxies_creation_date') do
        feature(:foreman_database).
          query("select id, created_at from smart_proxies").
          to_h { |row| [row['id'], row['created_at']] }
      end
    end

    def rbac_fields
      data_field('total_users_count') { sql_count('users') }
      data_field('non_admin_users_count') { sql_count('users where admin = false') }

      data_field('custom_roles_count') { sql_count('roles where origin = null') }

      merge_data('taxonomies_counts') do
        feature(:foreman_database).
          query("select type, count(*) from taxonomies group by type").
          to_h { |row| [row['type'], row['count'].to_i] }
      end
    end

    def settings_fields
      data_field('modified_settings') do
        feature(:foreman_database).
          query("select name from settings").
          map { |setting_line| setting_line['name'] }.
          join(',')
      end
    end

    def bookmarks_fields
      merge_data('bookmarks_by_public_by_type') do
        feature(:foreman_database).
          query(
            <<-SQL
              select public, owner_type, count(*)
              from bookmarks
              group by public, owner_type
            SQL
          ).
          to_h do |row|
            [
              "#{row['public'] ? 'public' : 'private'}#{flatten_separator}#{row['owner_type']}",
              row['count'].to_i,
            ]
          end
      end
      # bookmarks_by_owner =
      #   feature(:foreman_database).
      #   query(
      #     <<-SQL
      #       select owner_type, owner_id, count(*)
      #       from bookmarks
      #       group by owner_type, owner_id
      #     SQL
      #   ).
      #   to_h do |row|
      #     [
      #       "#{row['owner_type']}#{flatten_separator}#{row['owner_id']}",
      #       row['count'].to_i,
      #     ]
      #   end
    end
  end
end
