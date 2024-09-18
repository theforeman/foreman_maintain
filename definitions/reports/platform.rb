# copy the file and add the .rb suffix
module Checks
  module Report
    class Platform < ForemanMaintain::Report
      metadata do
        description 'Report about platform usages'
      end

      def run
        # General
        smart_proxies_count = feature(:foreman_database).query("select count(*) from smart_proxies").first['count'].to_i
        smart_proxies_creation_date = feature(:foreman_database).query("select id, created_at from smart_proxies")

        #RBAC
        total_users_count = feature(:foreman_database).query("select count(*) from users").first['count'].to_i
        non_admin_users_count = feature(:foreman_database).query("select count(*) from users where admin = false").first['count'].to_i

        custom_roles_count = feature(:foreman_database).query("select count(*) from roles where origin = null").first['count'].to_i
        taxonomies_counts = feature(:foreman_database).query("select type, count(*) from taxonomies group by type")

        #Settings
        modified_settings = feature(:foreman_database).query("select name from settings")

        #User groups
        user_groups_count = feature(:foreman_database).query("select count(*) from usergroups").first['count'].to_i

        #User groups
        user_groups_count = feature(:foreman_database).query("select count(*) from usergroups").first['count'].to_i

        #Bookmarks
        bookmarks = feature(:foreman_database).query("select id, public, owner_id, owner_type from bookmarks")

        #Mail notifications
        users_per_mail_notification = feature(:foreman_database).query("select max(mail_notifications.name) as notification_name, count(user_mail_notifications.user_id) from user_mail_notifications inner join mail_notifications on mail_notification_id = mail_notifications.id group by mail_notification_id")

        #Webhooks
        #TODO

        self.data = {
          smart_proxies_count: proxies_count,
          smart_proxies_creation_date: proxies_creation_date,
          total_users_count: total_users_count,
          non_admin_users_count: non_admin_users_count,
          custom_roles_count: custom_roles_count,
          taxonomies_counts: taxonomies_counts,
          modified_settings: modified_settings,
          user_groups_count: user_groups_count,
          user_groups_count: user_groups_count,
          bookmarks: bookmarks,
          users_per_mail_notification: users_per_mail_notification,
        }
      end
    end
  end
end
