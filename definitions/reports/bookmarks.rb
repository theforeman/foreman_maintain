# frozen_string_literal: true

module Reports
  class Bookmarks < ForemanMaintain::Report
    metadata do
      description 'Report about bookmark usage'
    end

    def run
      public_count = bookmarks_custom_public_count
      private_count = bookmarks_custom_private_count

      data_field('bookmarks_custom_public_count') { public_count }
      data_field('bookmarks_custom_private_count') { private_count }
      data_field('bookmarks_custom_count') { public_count + private_count }
    end

    private

    def bookmarks_custom_public_count
      # Count public bookmarks that are NOT owned by internal users
      bookmarks_not_owned_by_internal_users(public: true)
    end

    def bookmarks_custom_private_count
      # Count private bookmarks that are NOT owned by internal users
      bookmarks_not_owned_by_internal_users(public: false)
    end

    def bookmarks_not_owned_by_internal_users(public:)
      # Helper method to count bookmarks not owned by internal users with optional public filter
      public_condition = public ? 'AND b.public = true' : 'AND b.public = false'

      sql_count(
        <<~SQL
          bookmarks b
          WHERE (
            b.owner_type = 'User'
            #{public_condition}
            AND b.owner_id NOT IN (
              SELECT u.id
              FROM users u
              INNER JOIN auth_sources a ON u.auth_source_id = a.id
              WHERE a.type = 'AuthSourceHidden'
            )
          )
        SQL
      )
    end
  end
end
