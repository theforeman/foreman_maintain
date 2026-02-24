module Reports
  class Dashboard < ForemanMaintain::Report
    metadata do
      description 'Facts about the Foreman dashboard'
    end

    def run
      merge_data('dashboard_widgets_count') { dashboard_widgets_count_by_user }
    end

    private

    def dashboard_widgets_count_by_user
      return {} unless table_exists('widgets')
      query(
        <<-SQL
          SELECT user_id, COUNT(*) AS widget_count
          FROM widgets
          GROUP BY user_id
        SQL
      ).to_h { |row| ["User ID " + row['user_id'].to_s, row['widget_count'].to_i] }
    end
  end
end
